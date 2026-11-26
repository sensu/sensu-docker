#!/usr/bin/env bash
# Converts an Amazon Inspector findings JSON file (aws inspector2 list-findings)
# into a Markdown table and a CSV file.
#
# Usage: inspector-report.sh <findings.json> <report-title> <output-dir>
#
# Writes:
#   <output-dir>/report.md   Markdown: severity counts and a findings table
#   <output-dir>/results.csv one row per finding
#
# Rows are sorted by severity (CRITICAL, HIGH, MEDIUM, LOW), then by CVSS score
# (highest first). Findings without a CVE id (for example "Platform End Of Life")
# show their title in the CVE column.
set -euo pipefail

findings="${1:-}"
title="${2:-}"
outdir="${3:-}"

if [ -z "${findings}" ] || [ -z "${title}" ] || [ -z "${outdir}" ]; then
    echo "usage: $0 <findings.json> <report-title> <output-dir>" >&2
    exit 1
fi

mkdir -p "${outdir}"

# Normalise each finding to a flat record. jq does the sorting and formatting so
# the script stays free of table-building logic.
rows='
  def sev: {"CRITICAL":0,"HIGH":1,"MEDIUM":2,"LOW":3,"INFORMATIONAL":4,"UNTRIAGED":5}[.] // 9;
  [ (.findings // [])[] | {
      severity: (.severity // "UNTRIAGED"),
      cve: (.title // .vulnerabilityId // "-"),
      package: (.packageVulnerabilityDetails.vulnerablePackages[0].name // "-"),
      installed: (.packageVulnerabilityDetails.vulnerablePackages[0].version // "-"),
      fixed: (.packageVulnerabilityDetails.vulnerablePackages[0].fixedInVersion // "-"),
      score: (.inspectorScore // null)
  } ]
  | sort_by([(.severity | sev), -((.score // 0) * 10)])
'

jq -c "${rows}" "${findings}" > "${outdir}/rows.json"

# Markdown: severity totals, then one row per finding.
{
    echo "### ${title}"
    echo
    total="$(jq 'length' "${outdir}/rows.json")"
    echo "Total findings: **${total}**"
    echo
    echo "| Severity | Count |"
    echo "| --- | ---: |"
    for s in CRITICAL HIGH MEDIUM LOW; do
        n="$(jq --arg s "${s}" '[.[] | select(.severity == $s)] | length' "${outdir}/rows.json")"
        echo "| ${s} | ${n} |"
    done
    echo
    if [ "${total}" = "0" ]; then
        echo "No findings."
    else
        echo "| CVE | Package | Installed | Fixed in | CVSS score | Status |"
        echo "| --- | --- | --- | --- | ---: | --- |"
        jq -r '.[] | "| \(.cve) | \(.package) | \(.installed) | \(.fixed) | \(if .score == null then "-" else (.score | tostring) end) | \(.severity) |"' \
            "${outdir}/rows.json"
    fi
} > "${outdir}/report.md"

# CSV for spreadsheets and archiving.
{
    echo "Severity,CVE,Package,Installed,Fixed in,CVSS score"
    jq -r '.[] | [.severity, .cve, .package, .installed, .fixed, (if .score == null then "" else (.score | tostring) end)] | @csv' \
        "${outdir}/rows.json"
} > "${outdir}/results.csv"

rm -f "${outdir}/rows.json"
echo "wrote ${outdir}/report.md and ${outdir}/results.csv"
