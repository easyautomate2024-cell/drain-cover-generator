# Simple static file HTTP server using PowerShell
$port = 3333
$root = Split-Path $MyInvocation.MyCommand.Path

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving at http://localhost:$port/  (root: $root)"

while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response

    try {
        $path = $req.Url.LocalPath.TrimStart('/')
        if ($path -eq '') { $path = 'index.html' }
        $file = Join-Path $root $path

        if (Test-Path $file -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            $mime = switch ($ext) {
                '.html' { 'text/html; charset=utf-8' }
                '.js'   { 'application/javascript' }
                '.css'  { 'text/css' }
                '.json' { 'application/json' }
                default { 'application/octet-stream' }
            }
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $resp.ContentType = $mime
            $resp.StatusCode  = 200
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $resp.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $resp.OutputStream.Write($msg, 0, $msg.Length)
        }
    } catch {
        Write-Host "Error: $_"
    } finally {
        $resp.OutputStream.Close()
    }
}
