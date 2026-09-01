public class RulesDeployCallback implements Metadata.DeployCallback{
	 public void handleResult(Metadata.DeployResult result,
                             Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            // Deployment was successful
            List<Rule_Modify__e> eventsList = new List<Rule_Modify__e>();

            List<Metadata.DeployMessage> componentSuccess = result.details.componentSuccesses;

            for(Metadata.DeployMessage component : componentSuccess){
                Rule_Modify__e  eve = new Rule_Modify__e(Is_Success__c = true, MetaData_Name__c = component.fullName, Deployment_Id__c = component.Id);
                eventsList.add(eve);
            }
            List<Database.SaveResult> results = EventBus.publish(eventsList);
            System.debug(results);
        } else {
            // Deployment was not successful
            List<Rule_Modify__e> eventsList = new List<Rule_Modify__e>();
            List<Metadata.DeployMessage> componentSuccess = result.details.componentFailures ;
             for(Metadata.DeployMessage component : componentSuccess){
                Rule_Modify__e  eve = new Rule_Modify__e(Is_Success__c = false, MetaData_Name__c = component.fullName, Deployment_Id__c = component.Id);
                eventsList.add(eve);
            }
            List<Database.SaveResult> results = EventBus.publish(eventsList);
            System.debug(result.details);
        }
    }
}