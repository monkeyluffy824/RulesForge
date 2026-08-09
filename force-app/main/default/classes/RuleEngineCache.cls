public class RuleEngineCache {
	private static Map<String,List<RuleDefinition>> rulesByObject = new Map<String,List<RuleDefinition>>();
    private static Map<String,FunctionDefinition> functionRegistory;
    private static Boolean areFunctionsLoaded = false;
    
    public static List<RuleDefinition> getRulesForObject(String objectName){
        if(String.isBlank(objectName)){
            throw new AuraHandledException('Object Name Can not be blank'); // To be changed later to custom handled exception.
        }
        if(!rulesByObject.containsKey(objectName)){
            loadRulesForObject(objectName);
        }
        
        return rulesByObject.get(objectName);
    }
    
    private static void loadRulesForObject(String objectName){
        List<RuleDefinition> rules = new List<RuleDefinition>();
        
        List<RuleEngine_Rule__mdt> rulesMeta = [SELECT DeveloperName,Object_API_Name__c,Expression__c,Error_Message__c,Is_Active__c,Execution_Order__c,Has_Parent_Fields__c,
                                               Execute_Before_Insert__c,Execute_Before_Update__c,Execute_Before_Delete__c,
                                               AST_Chunk_1__c,AST_Chunk_2__c,AST_Chunk_3__c,AST_Chunk_4__c,AST_Chunk_5__c FROM RuleEngine_Rule__mdt WHERE Is_Active__c = true AND Object_API_Name__c = :objectName ORDER BY  Execution_Order__c ASC LIMIT 101];
        
        if(rulesMeta.size()>=101){
           throw new AuraHandledException('For an Given Object there can be only 100 Active Rules at a time'); // To be changed later to custom handled exception.
        }
        
        for(RuleEngine_Rule__mdt ruleMeta: rulesMeta){
            rules.add(new RuleDefinition(ruleMeta));
        }
        
        rulesByObject.put(objectName,rules);
    }
    
    public static Map<String,FunctionDefinition> getFunctionRegistory(){
        if(!areFunctionsLoaded){
            loadFunctions();
        }
        
        return functionRegistory;
    }
    
    private static void loadFunctions(){
        functionRegistory = new Map<String,FunctionDefinition>();
        List<RuleEngine_Function__mdt> funs = [SELECT Id,Function_Name__c,Class_Name__c,Argument_Count__c,Return_Type__c,Is_Built_In__c,Is_Active__c FROM RuleEngine_Function__mdt WHERE Is_Active__c = true LIMIT 201];
        if(funs.size()>=201){
            throw new AuraHandledException('For an Given Org there can be only 200 Active Functions at a given time'); // To be changed later to custom handled exception.
        }
        for(RuleEngine_Function__mdt fun: funs){
            functionRegistory.put(fun.Function_Name__c.toUpperCase(),new FunctionDefinition(fun));
        }
        
        areFunctionsLoaded = true;
    }
    
    public static void resetCache(){
        functionRegistory = null;
        rulesByObject.clear();
        areFunctionsLoaded = false;
    }
}