function bloodtext ($text) {Write-Host $text -BackgroundColor Black -ForegroundColor Red }
bloodtext ("Hello Andrew")
Start-Sleep 2
bloodtext ("I've been watching you...")
Start-Sleep 3
bloodtext ("And guess what?")
Start-Sleep 2
bloodtext ("I decided")
Start-Sleep 4
"You're my best friend!!!!!! See ya tonight!" | Out-File -FilePath $home\desktop\hi_andrew.txt
& $home\desktop\hi_andrew.txt