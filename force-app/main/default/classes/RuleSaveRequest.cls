public class RuleSaveRequest {
	@AuraEnabled public String developerName { get; set; }
    @AuraEnabled public String label { get; set; }
    @AuraEnabled public String objectApiName { get; set; }
    @AuraEnabled public String expression { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
    @AuraEnabled public Boolean isActive { get; set; }
    @AuraEnabled public String executionOrder { get; set; }
    @AuraEnabled public Boolean hasParentFields { get; set; }
    
    @AuraEnabled public Boolean executeBeforeInsert { get; set; }
    @AuraEnabled public Boolean executeBeforeDelete { get; set; }
    @AuraEnabled public Boolean executeBeforeUpdate { get; set; }
    
    @AuraEnabled public List<String> chunks { get; set; }
      
}