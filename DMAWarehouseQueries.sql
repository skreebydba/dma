USE DMAWarehouse;
/* Query to return rule titles and recommendations for all results */
SELECT DISTINCT dr.Title, dr.Recommendation
FROM DMAWarehouse.dbo.FactAssessment fa
INNER JOIN DMAWarehouse.dbo.dimRules dr
ON dr.RulesKey = fa.RulesKey 

/* Select all results from the processed assessments, including RuleID in case exclusions are needed */
SELECT DISTINCT fa.InstanceName, fa.DatabaseName, fa.ImpactedObjectName, dr.RuleID, ds.Severity, dr.Title, dr.Recommendation, fa.ImpactDetail
FROM DMAWarehouse.dbo.FactAssessment fa
INNER JOIN DMAWarehouse.dbo.dimRules dr
ON dr.RulesKey = fa.RulesKey
INNER JOIN DMAWarehouse.dbo.dimSeverity ds
ON ds.Severitykey = fa.SeverityKey
ORDER BY fa.DatabaseName, fa.ImpactedObjectName, dr.RuleID;

/* Assessment results excluding false positives
   See assessment document for additional details */
SELECT DISTINCT fa.InstanceName, fa.DatabaseName, fa.ImpactedObjectName, ds.Severity, dr.Title, dr.Recommendation, fa.ImpactDetail
FROM DMAWarehouse.dbo.FactAssessment fa
INNER JOIN DMAWarehouse.dbo.dimRules dr
ON dr.RulesKey = fa.RulesKey
INNER JOIN DMAWarehouse.dbo.dimSeverity ds
ON ds.Severitykey = fa.SeverityKey
WHERE dr.Title NOT LIKE '%71501%'
AND dr.Title NOT LIKE '%Microsoft.Rules.Data.Upgrade.UR00326%'
ORDER BY dr.Title;

/* Count of rules grouped by instance and databases name */
SELECT fa.InstanceName,
fa.DatabaseName,
fa.RulesKey,
dr.Title,
COUNT(*) AS RuleCount
FROM DMAWarehouse.dbo.FactAssessment fa
INNER JOIN dimRules dr
ON dr.RulesKey = fa.RulesKey
WHERE dr.Title NOT LIKE '%71501%'
AND dr.Title NOT LIKE '%Microsoft.Rules.Data.Upgrade.UR00326%'
GROUP BY fa.InstanceName,
fa.DatabaseName,
fa.RulesKey,
dr.Title
ORDER BY InstanceName,
DatabaseName;

/* Count of errors including source compatibility level and severity */
SELECT dsc.SourceCompatibilityLevel,
dr.Title,
ds.Severity,
COUNT(*) AS RuleCount
FROM DMAWarehouse.dbo.FactAssessment fa
INNER JOIN dimRules dr
ON dr.RulesKey = fa.RulesKey
INNER JOIN dimSeverity ds
ON ds.Severitykey = fa.SeverityKey
INNER JOIN dimSourceCompatibility dsc
ON dsc.SourceCompatKey = fa.SourceCompatKey
WHERE dr.Title NOT LIKE '%71501%'
AND dr.Title NOT LIKE '%Microsoft.Rules.Data.Upgrade.UR00326%'
GROUP BY dsc.SourceCompatibilityLevel,
dr.Title,
ds.Severity
ORDER BY ds.Severity;

/* Total count of rules from all assessments */
SELECT 
dr.RuleID,
dr.Title,
dr.ChangeCategory,
ds.Severity,
COUNT(*) AS RuleCount
FROM DMAWarehouse.dbo.FactAssessment fa
INNER JOIN dimRules dr
ON dr.RulesKey = fa.RulesKey
INNER JOIN dimSeverity ds
ON ds.Severitykey = fa.SeverityKey
WHERE dr.Title NOT LIKE '%71501%'
AND dr.Title NOT LIKE '%Microsoft.Rules.Data.Upgrade.UR00326%'
GROUP BY 
dr.RuleId,
dr.Title,
dr.ChangeCategory,
ds.Severity
ORDER BY ds.Severity;
