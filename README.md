# Disk Usage Analyzer

A high-performance terminal utility written in Crystal for analyzing disk usage in directories. It helps you identify which files and directories are consuming the most space on your system.

## Features

- 📊 Recursive directory scanning
- 📏 Human-readable file sizes
- 🔍 Customizable number of results
- 📂 Hidden files filtering
- 🔄 Multiple sorting options
- 📜 Various output formats (human-readable, JSON, CSV)
- 🚦 Progress tracking and verbose mode
- 🎨 Colorized output
- ⚡ Efficient error handling and permission management
- 📋 Detailed analysis summaries

## Installation

### Prerequisites

Make sure you have [Crystal](https://crystal-lang.org/install/) installed on your system.

### Building

Clone the repository and build the project:

```bash
git clone https://github.com/d8barcelos/disk_analyzer.git
cd disk_analyzer
crystal build src/disk_usage_analyzer.cr --release
```

## Usage

Basic syntax:
```bash
./disk_usage_analyzer [options] <directory>
```

### Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-n NUMBER` | `--top=NUMBER` | Number of entries to display (default: 10) |
| `-m SIZE` | `--min-size=SIZE` | Minimum size to include (in bytes) |
| `-s SORT` | `--sort-by=SORT` | Sort by: size, name, modified (default: size) |
| `-f FORMAT` | `--format=FORMAT` | Output format: human, json, csv (default: human) |
| `-a` | `--all` | Show hidden files and directories |
| `-v` | `--verbose` | Show detailed progress and errors |
| `-h` | `--help` | Show help message |
| | `--version` | Show version information |

### Examples

1. List top 5 largest items in your home directory:
```bash
./disk_usage_analyzer -n 5 ~/
```

2. Show all files (including hidden) larger than 1MB, sorted by name:
```bash
./disk_usage_analyzer -a -m 1000000 -s name ~/Documents
```

3. Export results in JSON format:
```bash
./disk_usage_analyzer -f json ~/Projects > analysis.json
```

4. Get detailed progress information:
```bash
./disk_usage_analyzer -v ~/Downloads
```

### Sample Output

Human-readable format:
```
Top 10 space consumers in '/home/user':
1. 📁 /home/user/Videos - 15.25 GB
2. 📁 /home/user/Downloads - 10.78 GB
3. 📁 /home/user/Documents - 5.42 GB
4. 📁 /home/user/Music - 2.15 GB
5. 📁 /home/user/Pictures - 1.89 GB
```

## Performance

The analyzer is designed to be efficient and can handle large directories with thousands of files. When running in verbose mode, it provides real-time statistics about:

- Total size processed
- Number of files analyzed
- Processing speed
- Time taken for analysis

## Error Handling

The analyzer gracefully handles various scenarios:
- Permission denied errors
- Non-existent directories
- Broken symlinks
- Inaccessible files