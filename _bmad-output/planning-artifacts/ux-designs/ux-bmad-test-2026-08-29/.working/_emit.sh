#!/bin/zsh
# emit <File.dc.html>  — reads body from stdin, wraps in the standard DC shell
f="$1"
cat > "$f" <<'HEAD'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap">
  <style>
    body { margin: 0; font-family: 'Noto Sans Bengali', 'Noto Sans', system-ui, sans-serif; }
    a { color: #2C6355; } a:hover { color: #1F4A3F; }
  </style>
</helmet>
HEAD
cat >> "$f"
printf '</x-dc>\n</body>\n</html>\n' >> "$f"
echo "  $f"
