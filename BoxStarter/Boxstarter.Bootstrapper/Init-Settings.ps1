if(!$Global:Boxstarter) { $Global:Boxstarter = @{} }
$Boxstarter.Log="$(Get-BoxstarterTempDir)\boxstarter.log"
$Boxstarter.RebootOk=$false
$Boxstarter.IsRebooting=$false
