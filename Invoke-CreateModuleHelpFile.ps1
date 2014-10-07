function Invoke-CreateModuleHelpFile {
    <#
        .SYNOPSIS
        Create a HTML help file for a PowerShell module.

        .DESCRIPTION
        This function will generate a full HTML help file for all commands in a PowerShell module.

        .EXAMPLE
        Invoke-CreateModuleHelpFile -ModuleName 'MyModule' -Path 'c:\temp\MyModuleHelp.html'

        This will generate a help file for 'MyModule' and save it as 'c:\temp\MyModuleHelp.html'

        .NOTES
        This function is dependent on jquery, the bootstrap framework and the jasny bootstrap add-on.

        Author: Øyvind Kallstad @okallstad
        Version: 1.0
    #>
    [CmdletBinding()]
    param(
        # Name of module. Note! The module must be imported before running this function.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        # Full path and filename to the generated html helpfile.
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # jquery filename - remember to update if you update jquery to a newer version
    $jqueryFileName = 'jquery-1.11.1.min.js'

    # define dependencies
    $dependencies = @('bootstrap.min.css','jasny-bootstrap.min.css','navmenu.css',$jqueryFileName,'bootstrap.min.js','jasny-bootstrap.min.js')

    try {
        # check dependencies
        $missingDependency = $false
        foreach($dependency in $dependencies) {
            if(-not(Test-Path -Path ".\$($dependency)")) {
                Write-Warning "Missing: $($dependency)"
                $missingDependency = $true
            }
        }
        if($missingDependency) { break }
        Write-Verbose 'Dependency check OK'

        # add System.Web - used for html encoding
        Add-Type -AssemblyName System.Web

        # try to get module info from imported modules first
        $moduleData = Get-Module -Name $ModuleName

        # abort if no module data returned
        if(-not ($moduleData)) {
            Write-Warning "The module '$($ModuleName)' was not found. Make sure that the module is imported before running this function."
            break
        }

        # abort if return type is wrong
        if(($moduleData.GetType()).Name -ne 'PSModuleInfo') {
            Write-Warning "The module '$($ModuleName)' did not return an object of type PSModuleInfo."
            break
        }

        # get module commands
        $moduleCommands = $moduleData.ExportedCommands | Select-Object -ExpandProperty 'Keys'
        Write-Verbose 'Got Module Commands OK'

        # start building html
        $html = @"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <title>$($ModuleName)</title>
    <link href="bootstrap.min.css" rel="stylesheet">
    <link href="jasny-bootstrap.min.css" rel="stylesheet">
    <link href="navmenu.css" rel="stylesheet">
    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="navmenu navmenu-default navmenu-fixed-left offcanvas-sm hidden-print">
      <nav class="sidebar-nav" role="complementary">
      <a class="navmenu-brand visible-md visible-lg" href="#" data-toggle="tooltip" title="$($ModuleName)">$($ModuleName)</a>
      <ul class="nav navmenu-nav">
        <li><a href="#About">About</a></li>

"@

        # loop through the commands to build the menu structure
        foreach($command in $moduleCommands) {
            $html += @"
          <!-- $($command) Menu -->
          <li class="dropdown">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown">$($command) <b class="caret"></b></a>
          <ul class="dropdown-menu navmenu-nav">
            <li><a href="#$($command)-Synopsis">Synopsis</a></li>
            <li><a href="#$($command)-Syntax">Syntax</a></li>
            <li><a href="#$($command)-Description">Description</a></li>
            <li><a href="#$($command)-Parameters">Parameters</a></li>
            <li><a href="#$($command)-Inputs">Inputs</a></li>
            <li><a href="#$($command)-Outputs">Outputs</a></li>
            <li><a href="#$($command)-Examples">Examples</a></li>
            <li><a href="#$($command)-RelatedLinks">RelatedLinks</a></li>
            <li><a href="#$($command)-Notes">Notes</a></li>
          </ul>
        </li>
        <!-- End $($command) Menu -->

"@
        }

        # finishing up the menu and starting on the main content
        $html += @"
        <li><a class="back-to-top" href="#top"><small>Back to top</small></a></li>
      </ul>
    </nav>
    </div>
    <div class="navbar navbar-default navbar-fixed-top hidden-md hidden-lg hidden-print">
      <button type="button" class="navbar-toggle" data-toggle="offcanvas" data-target=".navmenu">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="#">$($ModuleName)</a>
    </div>
    <div class="container">
      <div class="page-content">
        <!-- About $($ModuleName) -->
        <h1 id="About" class="page-header">About $($ModuleName)</h1>
        <div class="row">
          <div class="col-md-4 col-xs-4">
            Description<br>
            ModuleBase<br>
            Version<br>
            Author<br>
            CompanyName<br>
            Copyright
          </div>
          <div class="col-md-6 col-xs-6">
            $([System.Web.HttpUtility]::HtmlEncode($moduleData.Description))<br>
            $([System.Web.HttpUtility]::HtmlEncode($moduleData.ModuleBase))<br>
            $([System.Web.HttpUtility]::HtmlEncode($moduleData.Version))<br>
            $([System.Web.HttpUtility]::HtmlEncode($moduleData.Author))<br>
            $([System.Web.HttpUtility]::HtmlEncode($moduleData.CompanyName))<br>
            $([System.Web.HttpUtility]::HtmlEncode($moduleData.Copyright))
          </div>
        </div>
        <br>
        <!-- End About -->

"@

        # loop through the commands again to build the main content
        foreach($command in $moduleCommands) {
            $commandHelp = Get-Help $command
            $html += @"
        <!-- $($command) -->
        <div class="panel panel-default">
          <div class="panel-heading">
            <h2 id="$($command)-Header">$($command)</h1>
          </div>
          <div class="panel-body">
            <h3 id="$($command)-Synopsis">Synopsis</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.Synopsis))</p>
            <h3 id="$($command)-Syntax">Syntax</h3>

"@

            # get and format the command syntax
            $syntaxString = ''
            foreach($syntax in ($commandHelp.syntax.syntaxItem)) {
                $syntaxString += "$($syntax.name)"
                foreach ($syntaxParameter in ($syntax.parameter)) {
                    $syntaxString += ' '
                    # parameter is required
                    if(($syntaxParameter.required) -eq 'true') {
                        $syntaxString += "-$($syntaxParameter.name)"
                        if($syntaxParameter.parameterValue) { $syntaxString += " <$($syntaxParameter.parameterValue)>" }
                    }
                    # parameter is not required
                    else {
                        $syntaxString += "[-$($syntaxParameter.name)"
                        if($syntaxParameter.parameterValue) { $syntaxString += " <$($syntaxParameter.parameterValue)>]" }
                        elseif($syntaxParameter.parameterValueGroup) { $syntaxString += " {$($syntaxParameter.parameterValueGroup.parameterValue -join ' | ')}]" }
                        else { $syntaxString += ']' }
                    }
                }
                $html += @"
            <pre>$([System.Web.HttpUtility]::HtmlEncode($syntaxString))</pre>

"@
                Remove-Variable -Name 'syntaxString'
            }

            $html += @"
            <h3 id="$($command)-Description">Description</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.Description.Text -join [System.Environment]::NewLine) -replace([System.Environment]::NewLine, '<br>'))</p>
            <h3 id="$($command)-Parameters">Parameters</h3>
            <dl class="dl-horizontal">

"@

            # get all parameter data
            foreach($parameter in ($commandHelp.parameters.parameter)) {
                $parameterValueText = "<$($parameter.parameterValue)>"
                $html += @"
              <dt data-toggle="tooltip" title="$($parameter.name)">-$($parameter.name)</dt>
              <dd>$([System.Web.HttpUtility]::HtmlEncode($parameterValueText))<br>
                $($parameter.description.Text)<br><br>
                <div class="row">
                  <div class="col-md-4 col-xs-4">
                    Required?<br>
                    Position?<br>
                    Default value<br>
                    Accept pipeline input?<br>
                    Accept wildchard characters?
                  </div>
                  <div class="col-md-6 col-xs-6">
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.required))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.position))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.defaultValue))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.pipelineInput))<br>
                    $([System.Web.HttpUtility]::HtmlEncode($parameter.globbing))
                  </div>
                </div>
                <br>
              </dd>

"@
            }

            $html += @"
            </dl>
            <h3 id="$($command)-Inputs">Inputs</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.inputTypes.inputType.type.name))</p>
            <h3 id="$($command)-Outputs">Outputs</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.returnTypes.returnType.type.name))</p>
            <h3 id="$($command)-Examples">Examples</h3>

"@
            # get all examples
            $exampleCount = 0
            foreach($commandExample in ($commandHelp.examples.example)) {
                $exampleCount++
                $html += @"
            <b>Example $($exampleCount.ToString())</b>
            <pre>$([System.Web.HttpUtility]::HtmlEncode($commandExample.code))</pre>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandExample.remarks.text -join [System.Environment]::NewLine) -replace([System.Environment]::NewLine, '<br>'))</p>
            <br>

"@
            }

            $html += @"
            <h3 id="$($command)-RelatedLinks">RelatedLinks</h3>
            <p><a href="$([System.Web.HttpUtility]::HtmlEncode($commandHelp.relatedLinks.navigationLink.uri -join ''))">$([System.Web.HttpUtility]::HtmlEncode($commandHelp.relatedLinks.navigationLink.uri -join ''))</a></p>
            <h3 id="$($command)-Notes">Notes</h3>
            <p>$([System.Web.HttpUtility]::HtmlEncode($commandHelp.alertSet.alert.text -join [System.Environment]::NewLine) -replace([System.Environment]::NewLine, '<br>'))</p>
            <br>
          </div>
        </div>
        <!-- End ConvertFrom-HexIP -->

"@
        }

        # finishing up the html
        $html += @"
        </div>
    </div><!-- /.container -->
    <script src="$($jqueryFileName)"></script>
"@
        $html += @'
    <script src="bootstrap.min.js"></script>
    <script src="jasny-bootstrap.min.js"></script>
    <script>$('body').scrollspy({ target: '.sidebar-nav' })</script>
    <script>
      $('[data-spy="scroll"]').on("load", function () {
        var $spy = $(this).scrollspy('refresh')
    })
    </script>
  </body>
</html>
'@

        Write-Verbose 'Generated HTML OK'

        # write html file
        $html | Out-File -FilePath $Path -Force -Encoding 'UTF8'
        Write-Verbose "$($Path) written OK"
    }

    catch {
        Write-Warning $_.Exception.Message
    }
}