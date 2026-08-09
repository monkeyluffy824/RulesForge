public class RulesDeployCallback implements Metadata.DeployCallback{
	 public void handleResult(Metadata.DeployResult result,
                             Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            // Deployment was successful
            System.debug(result);
        } else {
            // Deployment was not successful
            System.debug(result.details);
        }
    }
}