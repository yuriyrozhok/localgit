#AdFind: http://www.joeware.net/freetools/tools/adfind/usage.htm

Remove-Item C:\yrozhok\DYI\Security\users.csv

Get-Content C:\yrozhok\DYI\Security\dyiusers.txt | <#Select-Object -First 1 |#>  ForEach-Object {
	Write-Host $_
	c:\toolkit\adfind\adfind -sc email:"$_" samaccountname company department title Function Initials Section mail co l c displayName cn sn givenName telephoneNumber Extension mobile -csv |
		ConvertFrom-CSV |
		Add-Member -MemberType AliasProperty -Name UID -Value samaccountname -PassThru |
		Add-Member -MemberType AliasProperty -Name Country -Value co -PassThru |
		Add-Member -MemberType AliasProperty -Name City -Value l -PassThru |
		Add-Member -MemberType AliasProperty -Name CountryCode -Value c -PassThru |
		Add-Member -MemberType AliasProperty -Name LastName -Value sn -PassThru |
			Select-Object UID,Company,Department,Title, <#Function,Initials,Section,#> Mail,Country,CountryCode,City,DisplayName,LastName,GivenName,TelephoneNumber,Mobile |
				Export-CSV C:\yrozhok\DYI\Security\users.csv -Append -NoTypeInformation

}