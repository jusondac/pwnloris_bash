# Website Vulnerability Scanner

A comprehensive bash-based vulnerability scanner that analyzes websites for security vulnerabilities and identifies CVE numbers.

## Features

- **DNS Reconnaissance**: Gather DNS information and WHOIS data
- **Port Scanning**: Use nmap for comprehensive port scanning with vulnerability detection
- **Web Technology Detection**: Identify web technologies and frameworks
- **Web Vulnerability Scanning**: Use Nikto for web-specific vulnerability detection
- **Modern Vulnerability Scanning**: Use Nuclei for up-to-date vulnerability detection
- **CVE Identification**: Automatically extract and compile CVE numbers from scan results
- **Detailed Reporting**: Generate comprehensive reports with all findings

## Requirements

### Required Tools
- `nmap` - Network exploration and port scanning
- `curl` - HTTP client for web requests
- `dig` - DNS lookup utility
- `whois` - Domain registration information

### Optional Tools (recommended)
- `nikto` - Web vulnerability scanner
- `nuclei` - Fast vulnerability scanner
- `whatweb` - Web technology identifier
- `jq` - JSON processor (for CVE lookup)
- `bc` - Calculator (for CVSS scoring)

## Installation

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y nmap curl dnsutils whois nikto jq bc

# Install Nuclei
GO111MODULE=on go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
# Or download from releases: https://github.com/projectdiscovery/nuclei/releases

# Install WhatWeb
sudo apt-get install whatweb
```

### CentOS/RHEL/Fedora
```bash
sudo yum install -y nmap curl bind-utils whois jq bc
# or
sudo dnf install -y nmap curl bind-utils whois jq bc

# For Nikto and WhatWeb, you may need to install from EPEL or compile from source
```

## Usage

### Basic Usage

```bash
# Simple scan
./vulnerability-scanner.sh example.com

# Verbose output
./vulnerability-scanner.sh -v example.com

# Deep scan (comprehensive port scan)
./vulnerability-scanner.sh -d example.com

# Custom output directory
./vulnerability-scanner.sh -o /tmp/my-scan example.com

# Full scan with all options
./vulnerability-scanner.sh -v -d -o /tmp/comprehensive-scan example.com
```

### CVE Analysis

```bash
# Look up a specific CVE
./cve-lookup.sh lookup CVE-2021-44228

# Analyze all CVEs from a scan
./cve-lookup.sh analyze vulnerability_scan_*/unique_cves.txt

# Generate HTML report
./cve-lookup.sh report vulnerability_scan_*/unique_cves.txt
```

## Command Line Options

### vulnerability-scanner.sh
- `-h, --help`: Show help message
- `-v, --verbose`: Enable verbose output
- `-d, --deep`: Enable deep scanning (slower but more thorough)
- `-o, --output DIR`: Custom output directory
- `-t, --templates DIR`: Custom nuclei templates directory

### cve-lookup.sh
- `lookup <CVE-ID>`: Look up details for a specific CVE
- `analyze <file>`: Analyze all CVEs in a file
- `report <file>`: Generate HTML report for CVEs in a file

## Output Files

The scanner creates a timestamped directory with the following files:

- `dns_recon.txt` - DNS and WHOIS information
- `nmap_scan.txt` - Port scan results with vulnerability scripts
- `web_technologies.txt` - Web technology detection results
- `nikto_scan.txt` - Nikto web vulnerability scan results
- `nuclei_scan.txt` - Nuclei vulnerability scan results
- `cves_from_*.txt` - CVEs extracted from each scan type
- `all_cves_found.txt` - All CVEs compiled together
- `unique_cves.txt` - Unique CVEs found (deduplicated)
- `vulnerability_report.txt` - Summary report

## Examples

### Example 1: Quick Scan
```bash
./vulnerability-scanner.sh google.com
```

### Example 2: Comprehensive Scan
```bash
./vulnerability-scanner.sh -v -d --output /tmp/target-scan target-website.com
```

### Example 3: CVE Analysis
```bash
# After running a scan
./cve-lookup.sh analyze vulnerability_scan_20231201_120000/unique_cves.txt
./cve-lookup.sh report vulnerability_scan_20231201_120000/unique_cves.txt
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Legal Usage**: Only scan websites you own or have explicit permission to test
2. **Rate Limiting**: Some scans may be aggressive; consider the target's resources
3. **False Positives**: Always verify vulnerability findings manually
4. **Updates**: Keep scanning tools updated for latest vulnerability signatures
5. **Responsible Disclosure**: Report found vulnerabilities responsibly

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x vulnerability-scanner.sh cve-lookup.sh
   ```

2. **Missing Tools**
   - The script will check for dependencies and provide installation commands
   - Install missing tools using your package manager

3. **Slow Scans**
   - Use `-v` for verbose output to see progress
   - Deep scans (`-d`) take longer but are more thorough
   - Consider scanning during off-peak hours

4. **No CVEs Found**
   - This is good news! The target may be properly secured
   - Try running with `-d` for deeper scanning
   - Ensure all optional tools are installed

### Debugging

Enable verbose mode and check individual output files:
```bash
./vulnerability-scanner.sh -v target.com
ls -la vulnerability_scan_*/
cat vulnerability_scan_*/vulnerability_report.txt
```

## Contributing

Feel free to submit issues and enhancement requests!

## Disclaimer

This tool is for educational and authorized security testing purposes only. Users are responsible for complying with applicable laws and regulations. The authors are not responsible for any misuse of this tool.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
