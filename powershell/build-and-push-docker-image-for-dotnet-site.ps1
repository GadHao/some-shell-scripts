function Get-HarborImageVersion {
    param (
        [string]$project_name, 
        [string]$repo_name
    )
    
    Write-Host "Docker project name:$project_name"
    Write-Host "Docker repository name:$repo_name"

    $result = curl.exe -sS -u username:password -X GET "https://repo.sample.com/api/v2.0/projects/$project_name/repositories/$repo_name/artifacts?with_tag=true"

    if (!$?) {
        Write-Error 'Query from the harbor registry fail'
        exit 1
    }

    $max_tag_name = ($result | ConvertFrom-Json).tags.name | Sort-Object | Select-Object -Last 1

    if (!$?) {
        Write-Error 'Can not get tag info from the harbor registry'
        exit 2
    }

    $version_number = ($max_tag_name.Split('.') | Select-Object -Last 1).Replace('v', '')

    if (!$version_number) {
        Write-Error 'Can not get version number from the harbor registry'
        exit 3
    }

    Write-Host "The version number of current repository is $version_number"

    return $version_number
}

function Publish-Project {
    Write-Host 'Searching publishConfig files...'
    $publish_configs = Get-ChildItem publishConfig.properties -Recurse
    
    if ($publish_configs.Count -eq 0) {
        Write-Error -Message 'There is no publishConfig.properties file in the solution folder'
        exit 1
    }
    
    $csproj_files = @()
    $project_configs = @{}
    
    # The config file should be put in the same folder as the project file
    foreach ($config_file in $publish_configs) {
        $config_file_directory = $config_file.Directory.FullName
        $project_file = Get-Item (Join-Path $config_file_directory *.csproj)
    
        if ($project_file.Count -ne 1) {
            Write-Error "There must be one and only one *.csproj file in $config_file_path"
            exit 2
        }
    
        $docker_file = Get-Item (Join-Path $config_file_directory Dockerfile)
    
        if ($docker_file.Count -ne 1) {
            Write-Error "There must be one and only one Dockerfile in $config_file_path"
            exit 3
        }
    
        $project_configs[$project_file.FullName] = Get-Content $config_file.FullName | ConvertFrom-StringData
        $csproj_files += $project_file
    }
    
    Write-Host "Find $($csproj_files.Count) project file(s)`n$($csproj_files.FullName)"
    
    $docker_image_names = @{}
    
    foreach ($item in $csproj_files) {
        # Read the content of .csproj file, find some useful information from it
        $csproj_file_xml = [xml](Get-Content $item.FullName)
        $project_name = $item.BaseName.ToLower()
        $project_conf = $project_configs[$item.FullName]

        if ($project_conf.ProjectName) {
            $project_name = $project_conf.ProjectName
        }
        elseif ($null -ne $csproj_file_xml.Project.PropertyGroup.AssemblyName) {
            $project_name = ($csproj_file_xml.Project.PropertyGroup.AssemblyName | Where-Object { $_ -ne $null }).ToLower()
        }
    
        Write-Host "Current project name:$project_name"
    
        $target_framework = ($csproj_file_xml.Project.PropertyGroup.TargetFramework | Where-Object { $_ -ne $null }).ToLower()
        Write-Host "Target Framework:$target_framework"
    
        Write-Host "Start to build project $project_name ..."
        $publish_path = Join-Path $item.Directory.FullName publish
        
        Write-Host "Publishing current project to $publish_path ..."
        dotnet publish $item.FullName -c Release -v q --nologo -o $publish_path
    
        if (!$?) {
            Write-Error "Publishing $project_name fail"
            exit 4
        }
    
        Write-Host "Successfully published project $project_name"
    
        if ($project_conf.ScriptAfterPublish) {
            $script_after_publish = Join-Path $item.Directory.FullName $project_conf.ScriptAfterPublish
            & $script_after_publish
            if (!$?) {
                Write-Error "The script after publish failed to execute"
                exit 5
            }
        }
        else {
            Write-Host "There is no scrpit need to execute"
        }
    
        $docker_project = 'web'
        $docker_repo = $project_name
        Write-Host 'Getting current project version number from docker...'
    
        $version = [int](Get-HarborImageVersion $docker_project $docker_repo) + 1
        
        if (!$?) {
            exit 6
        }
    
        $tag = Get-Date -Format 'yyyyMMdd'
        $docker_image = "$project_name`:$tag.v$version"
    
        $docker_image_names[$item.FullName] = $docker_image
    }
    
    Write-Host "All compilation work is completed, start to build image..."
    
    foreach ($file in $csproj_files) {
        Set-Location (Join-Path $file.Directory.FullName publish)
     
        docker build -t $docker_image_names[$file.FullName] .
        if (!$?) {
            Write-Error "The image $docker_image build failed"
            exit 7
        }
        docker tag $docker_image repo.sample.com/web/$docker_image
        docker push repo.sample.com/web/$docker_image
    
        if (!$?) {
            Write-Error "The image $docker_image push failed"
            exit 8
        }
    
        Write-Host "The image $docker_image was successfully pushed"
    }
}

Publish-Project $HarborProjectName
Write-Host "All images have been successfully pushed!!!"