USE DMAReporting2;

SELECT InstanceName,
Name AS DatabaseName,
ImpactedObjectName,
ImpactedObjectType,
SourceCompatibilityLevel,
SizeMB,
Severity,
ChangeCategory,
Title,
Impact,
Recommendation,
MoreInfo
FROM ReportData
WHERE Severity = N'Error'
AND RuleId <> 'StretchDB-High'
AND ImpactedObjectName IS NOT NULL;

SELECT Severity, ChangeCategory, Title, Impact, Recommendation, COUNT(*) AS SevCount
FROM ReportData
WHERE Severity <> 'NA'
AND Title LIKE 'Stretch%'
GROUP BY Severity, ChangeCategory, Title, Impact, Recommendation
ORDER BY COUNT(*) DESC;