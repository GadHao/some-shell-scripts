# 获取并对log字符串进行处理
$message = svn log -r HEAD
$message_array = ($message -split "`n")
$user = $message_array[1]
# 获取刚刚提交的版本号
$version = ($user -split "\|")[0].Trim('r').Trim()
# 获取用户名
$user = ($user -split "\|")[1]

# 获取当前仓库的svn地址
$path = svn info --show-item repos-root-url
Add-Type -AssemblyName System.Web
$url = [System.Web.HTTPUtility]::UrlDecode($path)

$message_with_paths = svn log -c $version -v
$message_with_paths = $message_with_paths | Select-Object -Skip 3
$changed_files = ($message_with_paths -split ('`n'))
$changed_message = ''
foreach ($filepath in $changed_files) {
    if ($filepath.Trim() -eq '') {
        break
    }
    $commit_detail = $filepath.Trim() -split " "
    $commit_type = ''
    $file_path = $commit_detail[1]
    switch ($commit_detail[0].Trim()) {
        'M' { $commit_type = '【修改】' }
        'A' { $commit_type = '【新增】' }
        'D' { $commit_type = '【删除】' }
    }
    $changed_message = "$changed_message `n $commit_type$url$file_path" 
}

$message_array = $message_array | Select-Object -Skip 3 | Select-Object -SkipLast 1
$commit_message = $message_array -join "`n"

$params = @{
    "msgtype" = "text";
    "text"    = @{
        "content" = "提交者: $user `n提交信息: $commit_message `n当前仓库路径: $url `n改动文件: $changed_message";
    };
}

$jsondata = $($params | ConvertTo-Json)

Invoke-WebRequest -Uri https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=307a31d6-464d-477f-83f2-e6dc77287946 -Method POST -Body ([System.Text.Encoding]::UTF8.GetBytes($jsondata)) -ContentType "application/json"