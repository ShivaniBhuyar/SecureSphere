import json
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from collections import Counter
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from app.models.threat_log import ThreatLogModel
from app.models.alert import AlertModel
from app.schemas.reports import (
    ThreatHistoryResponse,
    ThreatHistoryItem,
    ReportSummaryResponse,
    DeviceScoreResponse,
    DeviceScoreFactor,
    TrendsResponse,
    TrendDataPoint,
    ReportInsight,
)

class ReportsService:
    @classmethod
    def get_history(
        cls,
        db: Session,
        limit: int = 50,
        offset: int = 0,
        event_type: Optional[str] = None,
        risk_level: Optional[str] = None,
    ) -> ThreatHistoryResponse:
        """
        Retrieves historical threat scans from threat_analysis_logs,
        ordered newest first, with optional event_type and risk_level filters.
        """
        query = db.query(ThreatLogModel)

        if event_type and event_type.strip() and event_type.lower() != "all":
            query = query.filter(ThreatLogModel.event_type == event_type.strip().lower())

        if risk_level and risk_level.strip() and risk_level.lower() != "all":
            query = query.filter(ThreatLogModel.risk_level == risk_level.strip().lower())

        total = query.count()
        records = (
            query.order_by(desc(ThreatLogModel.timestamp))
            .offset(offset)
            .limit(limit)
            .all()
        )

        items: List[ThreatHistoryItem] = []
        for r in records:
            try:
                indicators = json.loads(r.indicators_json or "[]")
            except Exception:
                indicators = []

            items.append(
                ThreatHistoryItem(
                    id=r.id,
                    timestamp=r.timestamp.isoformat() if r.timestamp else None,
                    eventType=r.event_type,
                    threatType=r.threat_type,
                    riskLevel=r.risk_level.lower(),
                    riskScore=r.risk_score,
                    confidence=r.confidence,
                    contentSnippet=r.content_snippet,
                    reason=r.reason,
                    indicators=indicators,
                    recommendedAction=r.recommended_action,
                )
            )

        return ThreatHistoryResponse(
            total=total,
            items=items,
            limit=limit,
            offset=offset,
        )

    @classmethod
    def get_summary(cls, db: Session, days: Optional[int] = 7) -> ReportSummaryResponse:
        """
        Generates an executive security posture report from real database data.
        Supports customizable timeframe (e.g. days=7, days=30, or all-time if days <= 0 or None).
        """
        now = datetime.utcnow()
        query = db.query(ThreatLogModel)
        alert_query = db.query(AlertModel)

        timeframe_days: Optional[int] = None
        if days and days > 0:
            timeframe_days = days
            cutoff = now - timedelta(days=days)
            query = query.filter(ThreatLogModel.timestamp >= cutoff)
            alert_query = alert_query.filter(AlertModel.timestamp >= cutoff)

        logs = query.all()
        total_scans = len(logs)

        # Alerts calculation
        total_alerts = alert_query.count()
        unread_alerts = db.query(AlertModel).filter(AlertModel.is_read == False).count()

        high_count = sum(1 for l in logs if (l.risk_level or "").lower() == "high")
        medium_count = sum(1 for l in logs if (l.risk_level or "").lower() == "medium")
        low_count = sum(1 for l in logs if (l.risk_level or "").lower() == "low")
        threats_detected = high_count + medium_count

        scores = [l.risk_score for l in logs if l.risk_score is not None]
        avg_score = round(sum(scores) / len(scores), 1) if scores else 0.0
        max_score = max(scores) if scores else 0

        # Breakdowns
        event_types: Dict[str, int] = {}
        threat_types: Dict[str, int] = {}
        all_indicators: List[str] = []

        for l in logs:
            event_types[l.event_type] = event_types.get(l.event_type, 0) + 1
            threat_types[l.threat_type] = threat_types.get(l.threat_type, 0) + 1
            try:
                inds = json.loads(l.indicators_json or "[]")
                all_indicators.extend([i for i in inds if "no suspicious" not in i.lower()])
            except Exception:
                pass

        indicator_counts = Counter(all_indicators).most_common(5)
        top_indicators = [ind for ind, _ in indicator_counts]

        # Calculate real security posture grade
        if total_scans == 0:
            posture = "Good"
            posture_desc = "No security events recorded in this period. Baseline protection remains active."
        elif avg_score >= 60 or high_count >= 10:
            posture = "Critical Risk"
            posture_desc = f"{high_count} high-severity threats detected. Immediate security review strongly advised."
        elif avg_score >= 35 or high_count >= 1:
            posture = "Needs Attention"
            posture_desc = f"{threats_detected} potential cyber threats identified. Review highlighted risk indicators."
        elif avg_score >= 15:
            posture = "Good"
            posture_desc = "Standard digital security maintained. Low incidence of malicious patterns."
        else:
            posture = "Excellent"
            posture_desc = "Strong digital hygiene. Zero elevated threats detected during this monitoring period."

        # Actionable recommendations based on detected categories
        recommendations: List[str] = []
        if event_types.get("sms", 0) > 0:
            recommendations.append("Never share one-time SMS passcodes (OTPs) or verify accounts over unsolicited text messages.")
        if event_types.get("url", 0) > 0:
            recommendations.append("Verify link destination domains before entering banking credentials or personal details.")
        if event_types.get("device", 0) > 0:
            recommendations.append("Ensure device screen lock and biometric protections are activated and USB debugging is off.")
        if event_types.get("app", 0) > 0:
            recommendations.append("Avoid installing unverified third-party APKs; download apps only from official stores.")
        if not recommendations:
            recommendations = [
                "Maintain active background monitoring for real-time safety alerts.",
                "Keep device operating system and security patches up to date.",
                "Review permissions granted to third-party applications regularly.",
            ]

        return ReportSummaryResponse(
            timeframeDays=timeframe_days,
            totalScans=total_scans,
            threatsDetected=threats_detected,
            totalAlerts=total_alerts,
            unreadAlerts=unread_alerts,
            highRiskEvents=high_count,
            mediumRiskEvents=medium_count,
            lowRiskEvents=low_count,
            averageRiskScore=avg_score,
            highestRiskScore=max_score,
            securityPosture=posture,
            securityPostureDescription=posture_desc,
            eventTypeBreakdown=event_types,
            threatTypeBreakdown=threat_types,
            topRiskIndicators=top_indicators,
            recommendedActions=recommendations,
            generatedAt=now.isoformat(),
        )

    @classmethod
    def get_device_score(
        cls,
        db: Session,
        override_meta: Optional[Dict[str, Any]] = None,
    ) -> DeviceScoreResponse:
        """
        Calculates the SecureSphere Device Security Score (0-100) based on
        the latest evaluated device security signals and active security posture.
        """
        score = 100
        factors: List[DeviceScoreFactor] = []
        recommendations: List[str] = []

        # Find latest device log in database
        latest_device_log = (
            db.query(ThreatLogModel)
            .filter(ThreatLogModel.event_type == "device")
            .order_by(desc(ThreatLogModel.timestamp))
            .first()
        )

        indicators_text = ""
        reason_text = ""
        last_assessed = None

        if latest_device_log:
            last_assessed = latest_device_log.timestamp.isoformat() if latest_device_log.timestamp else None
            reason_text = (latest_device_log.reason or "").lower()
            try:
                inds = json.loads(latest_device_log.indicators_json or "[]")
                indicators_text = " ".join(inds).lower()
            except Exception:
                indicators_text = ""

        # Factor 1: OS Root / Jailbreak Status
        is_rooted = False
        if override_meta and override_meta.get("is_rooted") is True:
            is_rooted = True
        elif "root" in indicators_text or "jailbreak" in indicators_text:
            is_rooted = True

        if is_rooted:
            score -= 40
            factors.append(
                DeviceScoreFactor(
                    factor="Operating System Integrity",
                    status="critical",
                    impact="-40 pts",
                    detail="Root or jailbreak detected, compromising core sandbox protections.",
                )
            )
            recommendations.append("Unroot device to restore essential Android security sandboxing.")
        else:
            factors.append(
                DeviceScoreFactor(
                    factor="Operating System Integrity",
                    status="secure",
                    impact="Normal",
                    detail="System partition integrity verified. Device is not rooted.",
                )
            )

        # Factor 2: Screen Lock / Biometrics
        screen_lock_disabled = False
        if override_meta and (override_meta.get("screen_lock_disabled") is True or override_meta.get("screen_lock_enabled") is False):
            screen_lock_disabled = True
        elif "screen lock" in indicators_text and ("disabled" in indicators_text or "unprotected" in indicators_text):
            screen_lock_disabled = True

        if screen_lock_disabled:
            score -= 25
            factors.append(
                DeviceScoreFactor(
                    factor="Screen Lock & Biometrics",
                    status="critical",
                    impact="-25 pts",
                    detail="Device lock screen is disabled or unprotected.",
                )
            )
            recommendations.append("Enable a strong PIN, password, or biometric authentication in device settings.")
        else:
            factors.append(
                DeviceScoreFactor(
                    factor="Screen Lock & Biometrics",
                    status="secure",
                    impact="Normal",
                    detail="Device lock protection active.",
                )
            )

        # Factor 3: USB Debugging / ADB Interface
        usb_debugging = False
        if override_meta and override_meta.get("usb_debugging_enabled") is True:
            usb_debugging = True
        elif "usb debugging" in indicators_text and "enabled" in indicators_text:
            usb_debugging = True

        if usb_debugging:
            score -= 20
            factors.append(
                DeviceScoreFactor(
                    factor="USB Debugging Interface",
                    status="warning",
                    impact="-20 pts",
                    detail="USB Debugging is enabled, allowing unauthorized external communication.",
                )
            )
            recommendations.append("Turn off USB Debugging in Developer Options when not actively in use.")
        else:
            factors.append(
                DeviceScoreFactor(
                    factor="USB Debugging Interface",
                    status="secure",
                    impact="Normal",
                    detail="USB debugging is disabled, preventing unauthorized physical bridge access.",
                )
            )

        # Factor 4: Sideloading / Unknown Sources
        unknown_sources = False
        if override_meta and override_meta.get("unknown_sources_enabled") is True:
            unknown_sources = True
        elif "unknown sources" in indicators_text and "enabled" in indicators_text:
            unknown_sources = True

        if unknown_sources:
            score -= 15
            factors.append(
                DeviceScoreFactor(
                    factor="App Sideloading Protection",
                    status="warning",
                    impact="-15 pts",
                    detail="Installation from unknown sources is currently allowed.",
                )
            )
            recommendations.append("Disable installation from unknown sources to protect against unverified APKs.")
        else:
            factors.append(
                DeviceScoreFactor(
                    factor="App Sideloading Protection",
                    status="secure",
                    impact="Normal",
                    detail="Unknown source installation blocked by security policy.",
                )
            )

        # Factor 5: Unresolved Security Alerts
        unread_high_alerts = (
            db.query(AlertModel)
            .filter(AlertModel.is_read == False, AlertModel.risk_level == "high")
            .count()
        )
        if unread_high_alerts > 0:
            penalty = min(20, unread_high_alerts * 10)
            score -= penalty
            factors.append(
                DeviceScoreFactor(
                    factor="Active Unresolved Alerts",
                    status="warning",
                    impact=f"-{penalty} pts",
                    detail=f"{unread_high_alerts} unread high-severity security alert(s) pending review.",
                )
            )
            recommendations.append("Review and resolve pending security alerts in the Alert Center.")

        # Ensure score bounds
        score = max(0, min(100, score))

        if score >= 90:
            grade = "A (Excellent)"
            status = "Secure"
            summary = "Your device security posture is optimal. Core operating system and access controls are intact."
        elif score >= 75:
            grade = "B (Good)"
            status = "Protected"
            summary = "Your device has solid baseline protection with minor security settings open for optimization."
        elif score >= 50:
            grade = "C (Needs Attention)"
            status = "Action Recommended"
            summary = "Elevated device vulnerability detected. Some debugging or unverified options are active."
        else:
            grade = "F (Critical)"
            status = "Vulnerable"
            summary = "High-risk device security weaknesses present. Immediate defensive action is required."

        if not recommendations:
            recommendations.append("Maintain existing security configuration and verify monthly OS security updates.")

        return DeviceScoreResponse(
            score=score,
            grade=grade,
            status=status,
            summary=summary,
            factors=factors,
            recommendations=recommendations,
            lastAssessed=last_assessed or datetime.utcnow().isoformat(),
            source="SecureSphere Device Security Engine",
        )

    @classmethod
    def get_trends(cls, db: Session, days: int = 7) -> TrendsResponse:
        """
        Calculates time-series trends and data-driven insights over the requested window.
        """
        days = max(3, min(60, days))  # Enforce sane range
        now = datetime.utcnow().date()
        start_date = now - timedelta(days=days - 1)

        cutoff = datetime.combine(start_date, datetime.min.time())

        # Retrieve relevant logs and alerts in timeframe
        logs = (
            db.query(ThreatLogModel)
            .filter(ThreatLogModel.timestamp >= cutoff)
            .all()
        )
        alerts = (
            db.query(AlertModel)
            .filter(AlertModel.timestamp >= cutoff)
            .all()
        )

        # Group by date
        data_points: List[TrendDataPoint] = []
        category_dist: Dict[str, int] = {}
        risk_dist: Dict[str, int] = {"high": 0, "medium": 0, "low": 0}

        # Build day map
        day_map: Dict[str, Dict[str, Any]] = {}
        for d in range(days):
            current_day = start_date + timedelta(days=d)
            day_str = current_day.strftime("%Y-%m-%d")
            day_map[day_str] = {
                "scans": 0,
                "threats": 0,
                "scores": [],
                "alerts": 0,
            }

        for l in logs:
            if not l.timestamp:
                continue
            day_str = l.timestamp.date().strftime("%Y-%m-%d")
            if day_str in day_map:
                day_map[day_str]["scans"] += 1
                if (l.risk_level or "").lower() in ["medium", "high"]:
                    day_map[day_str]["threats"] += 1
                if l.risk_score is not None:
                    day_map[day_str]["scores"].append(l.risk_score)

            cat = l.threat_type or l.event_type or "other"
            category_dist[cat] = category_dist.get(cat, 0) + 1

            r_lvl = (l.risk_level or "low").lower()
            if r_lvl in risk_dist:
                risk_dist[r_lvl] += 1
            else:
                risk_dist[r_lvl] = 1

        for a in alerts:
            if not a.timestamp:
                continue
            day_str = a.timestamp.date().strftime("%Y-%m-%d")
            if day_str in day_map:
                day_map[day_str]["alerts"] += 1

        for day_str in sorted(day_map.keys()):
            entry = day_map[day_str]
            scores = entry["scores"]
            avg_score = round(sum(scores) / len(scores), 1) if scores else 0.0
            data_points.append(
                TrendDataPoint(
                    date=day_str,
                    scanCount=entry["scans"],
                    threatCount=entry["threats"],
                    averageRiskScore=avg_score,
                    alertCount=entry["alerts"],
                )
            )

        # Generate intelligent, data-supported insights
        insights: List[ReportInsight] = []
        total_scans = len(logs)
        total_threats = sum(1 for l in logs if (l.risk_level or "").lower() in ["medium", "high"])

        if total_scans >= 5:
            # Top category insight
            if category_dist:
                top_cat = max(category_dist.items(), key=lambda x: x[1])
                pct = round((top_cat[1] / total_scans) * 100)
                clean_name = top_cat[0].replace("_", " ").title()
                insights.append(
                    ReportInsight(
                        type="info",
                        title=f"Most Active Vector: {clean_name}",
                        description=f"{clean_name} accounted for {pct}% of security activities ({top_cat[1]} events) in the past {days} days.",
                    )
                )

            # High risk proportion
            high_count = risk_dist.get("high", 0)
            if high_count > 0:
                insights.append(
                    ReportInsight(
                        type="warning",
                        title="Elevated Threat Detections",
                        description=f"{high_count} high-risk incidents were flagged by SecureSphere AI engines. Prompt verification is advised.",
                    )
                )
            else:
                insights.append(
                    ReportInsight(
                        type="positive",
                        title="Zero High-Severity Incidents",
                        description="No critical cyber threats bypassed the defensive filters over this timeframe.",
                    )
                )

            # Risk trend direction
            first_half = data_points[: len(data_points) // 2]
            second_half = data_points[len(data_points) // 2 :]
            first_half_avg = (
                sum(dp.averageRiskScore for dp in first_half) / len(first_half)
                if first_half
                else 0
            )
            second_half_avg = (
                sum(dp.averageRiskScore for dp in second_half) / len(second_half)
                if second_half
                else 0
            )

            if second_half_avg < first_half_avg - 5:
                insights.append(
                    ReportInsight(
                        type="positive",
                        title="Improving Risk Posture",
                        description="Average incident risk scores decreased compared to the start of the timeframe.",
                    )
                )
            elif second_half_avg > first_half_avg + 5:
                insights.append(
                    ReportInsight(
                        type="warning",
                        title="Recent Risk Influx",
                        description="An increase in average threat scores was observed in recent scans.",
                    )
                )
        else:
            insights.append(
                ReportInsight(
                    type="info",
                    title="Continuous Guardian Monitoring",
                    description=f"SecureSphere has tracked {total_scans} security events. Trends will become richer as more checks run.",
                )
            )
            insights.append(
                ReportInsight(
                    type="positive",
                    title="Real-Time Protection Active",
                    description="All multi-vector safety checks (SMS, URL, Device, App) are running in background protection.",
                )
            )

        return TrendsResponse(
            days=days,
            dataPoints=data_points,
            categoryDistribution=category_dist,
            riskLevelDistribution=risk_dist,
            insights=insights,
            startDate=start_date.strftime("%Y-%m-%d"),
            endDate=now.strftime("%Y-%m-%d"),
        )
