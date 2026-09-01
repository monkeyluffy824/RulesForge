public class RuleEditorController {
	
    @AuraEnabled(cacheable = true)
    public static Map<String,String> getDirectFieldMetadata(String objName,String fieldName){
        Map<String,String> result = new Map<String,String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objName);
        
        if(objType == null){
            throw new AuraHandledException('Object Not found');
        }
        
        Map<String,Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
        
        if(fieldName != null){
            Schema.SObjectField fl = fields.get(fieldName);
            if(fl == null){
                throw new AuraHandledException('Given field Not found');
            }
            if(getTypeFromField(fl.getDescribe().getType()) == null){
                throw new AuraHandledException('Unsupported type for given field');
            }
            result.put(fl.getDescribe().getName(),getTypeFromField(fl.getDescribe().getType()));
            return result;
        }
        
        for(Schema.SObjectField fld: fields.values()){
            if(getTypeFromField(fld.getDescribe().getType()) == null){
                continue;
            }
            
            result.put(fld.getDescribe().getName(),getTypeFromField(fld.getDescribe().getType()));
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Map<String,String> getRelationshipMetadata(String objName, List<String> fldNames){
        if(fldNames.size() != 2){
             throw new AuraHandledException('Received Incorrect field references');
        }
        Map<String,String> result = new Map<String,String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objName);
        
        Schema.DescribeFieldResult targetField = null;
        
        if(objType == null){
            throw new AuraHandledException('Object Not found');
        }
        
        Map<String,Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
        
        for(Schema.SObjectField fld: fields.values()){
            if(getTypeFromField(fld.getDescribe().getType()) == null){
                continue;
            }
            
            if(fld.getDescribe().getType() === Schema.DisplayType.REFERENCE && fld.getDescribe().getRelationshipName() == fldNames[0]){
                targetField = fld.getDescribe();
                break;
            }
            
        }
        
        if(targetField == null){
            throw new AuraHandledException('Relationship Not found');
        }
        
        List <Schema.sObjectType> references = targetField.getReferenceTo();
        
        if(references.size()>1){
            throw new AuraHandledException('Parent Traversal is not supported for polymorphic reference fields');
        }
        
        return getDirectFieldMetadata(references[0].getDescribe().getName(),fldNames[1]);
    }
    
    
    @AuraEnabled(cacheable = true)
    public static String getFunctionMetadata(){
        Map<String,Object> functionRegistory = new Map<String,Object>();
        List<RuleEngine_Function__mdt> funs = [SELECT Id,Function_Name__c,Argument_Count__c,Return_Type__c FROM RuleEngine_Function__mdt WHERE Is_Active__c = true LIMIT 201];
        if(funs.size()>=201){
            throw new AuraHandledException('For an Given Org there can be only 200 Active Functions at a given time'); // To be changed later to custom handled exception.
        }
        for(RuleEngine_Function__mdt fun: funs){
            Map<String,object> json = new Map<String,Object>{
                'argCount' => fun.Argument_Count__c,
                'returnType' => fun.Return_Type__c
            };
            
            functionRegistory.put(fun.Function_Name__c.toUpperCase(),json);
        }
        
        return JSON.serialize(functionRegistory);
    }
    
    @AuraEnabled(cacheable = true)
    public static String getValidationSchema(){
        Map<String,Object> validateSchema = new Map<String,Object>();
        List<RuleEngine_Function__mdt> funs = [SELECT Id,Function_Name__c,Argument_Count__c,Argument_Schema__c FROM RuleEngine_Function__mdt WHERE Is_Active__c = true LIMIT 201];
        if(funs.size()>=201){
            throw new AuraHandledException('For an Given Org there can be only 200 Active Functions at a given time'); // To be changed later to custom handled exception.
        }
        for(RuleEngine_Function__mdt fun: funs){
            
            List<Object> argList = new List<Object>();
            List<String> args = fun.Argument_Schema__c.split(';');
            for(String arg: args){
                List<String> acceptedTypes = arg.split('\\|');
                Map<String,object> argJSON = new Map<String,Object>{
                    'acceptedTypes' => acceptedTypes
                };
                argList.add(argJSON);
            }
            
            validateSchema.put(fun.Function_Name__c.toUpperCase(),new Map<String,Object>{
                'args' => argList
            });
  
        }
        return JSON.serialize(validateSchema);
        
    }
    
    @AuraEnabled
    public static String saveRule(RuleSaveRequest request){
        System.debug(request);
        if(request.chunks == null || request.chunks.size() != 5){
            throw new AuraHandledException('Invalid Rule data'); // To be changed later to custom handled exception.
        }
        
        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = 'RuleEngine_Rule.'+ request.developerName;
        cmd.label = request.label;
        
        Map<String,String> fieldNames = new Map<String,String>{
            'objectApiName' => 'Object_API_Name__c','expression' => 'Expression__c','errorMessage' => 'Error_Message__c','developerName'=>'DeveloperName',
            'isActive' => 'Is_Active__c','executionOrder' => 'Execution_Order__c','hasParentFields' => 'Has_Parent_Fields__c','label' => 'MasterLabel',
            'executeBeforeInsert' => 'Execute_Before_Insert__c','executeBeforeDelete' => 'Execute_Before_Delete__c', 'executeBeforeUpdate'=>'Execute_Before_Update__c'
        };
            
        Map<String, Object> fieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(request));
        
        for(String fldName: fieldMap.keySet()){
            if(fldName == 'chunks' || fldName == 'label' || fldName == 'developerName'){
                continue;
            }
            Metadata.CustomMetadataValue value = new Metadata.CustomMetadataValue();
            value.field = fieldNames.get(fldName);
			value.value = fieldMap.get(fldName);
            System.debug(value);
			cmd.values.add(value);
        }
        
        for(Integer i=1;i<=request.chunks.size();i++){
            String fName = 'AST_Chunk_'+ i + '__c';
            Metadata.CustomMetadataValue value = new Metadata.CustomMetadataValue();
            value.field = fName;
			value.value = request.chunks[i-1];
            System.debug(value);
			cmd.values.add(value);
        }
        
        Metadata.DeployContainer container = new Metadata.DeployContainer();
		container.addMetadata(cmd);
        RulesDeployCallback callBac = new RulesDeployCallback();
		Id jobId  = Metadata.Operations.enqueueDeployment(container, callBac);
        
        return jobId;
    }

    @AuraEnabled(cacheable = true)
    public static RuleEngine_Rule__mdt getExistingRuleName(String ruleName){
        List<RuleEngine_Rule__mdt> rulesMeta = [SELECT DeveloperName,MasterLabel,Object_API_Name__c,Expression__c,Error_Message__c,Is_Active__c,Execution_Order__c,Has_Parent_Fields__c,
                                               Execute_Before_Insert__c,Execute_Before_Update__c,Execute_Before_Delete__c,
                                               AST_Chunk_1__c,AST_Chunk_2__c,AST_Chunk_3__c,AST_Chunk_4__c,AST_Chunk_5__c FROM RuleEngine_Rule__mdt WHERE DeveloperName = :ruleName LIMIT 1];
        if(rulesMeta.size()!= 1){
            throw new AuraHandledException('Not able to found any Rules with given Name');
        }

        return rulesMeta[0];
    }


    @AuraEnabled(cacheable = true)
    public static List<RuleEngine_Rule__mdt> getAllExistingRules(){
        try {
            List<RuleEngine_Rule__mdt> rulesMeta = [SELECT DeveloperName,MasterLabel,Object_API_Name__c,Expression__c,Error_Message__c,Is_Active__c,Execution_Order__c,Has_Parent_Fields__c,
                                               Execute_Before_Insert__c,Execute_Before_Update__c,Execute_Before_Delete__c,
                                               AST_Chunk_1__c,AST_Chunk_2__c,AST_Chunk_3__c,AST_Chunk_4__c,AST_Chunk_5__c FROM RuleEngine_Rule__mdt  WITH SYSTEM_MODE LIMIT 500];
            if(rulesMeta.size() == 0){
                throw new AuraHandledException('No rules found');
            }

            return rulesMeta;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
               
    
    private static String getTypeFromField( Schema.DisplayType fieldType){
        List<Schema.DisplayType> numberList = new List<Schema.DisplayType>{Schema.DisplayType.CURRENCY,Schema.DisplayType.DOUBLE,Schema.DisplayType.INTEGER,Schema.DisplayType.PERCENT,Schema.DisplayType.LONG};
        List<Schema.DisplayType> stringList = new List<Schema.DisplayType>{Schema.DisplayType.STRING,Schema.DisplayType.TEXTAREA,Schema.DisplayType.PICKLIST,Schema.DisplayType.MULTIPICKLIST,Schema.DisplayType.EMAIL,Schema.DisplayType.PHONE,Schema.DisplayType.URL,Schema.DisplayType.ID,Schema.DisplayType.REFERENCE,Schema.DisplayType.ENCRYPTEDSTRING,
																		   Schema.DisplayType.JSON,Schema.DisplayType.COMBOBOX};
        
            if(numberList.contains(fieldType)){
                return 'NUMBER';
            }else if(stringList.contains(fieldType)){
                return 'STRING';
            }else if(fieldType == Schema.DisplayType.DATE){
                return 'DATE';
            }else if(fieldType == Schema.DisplayType.DATETIME){
                return 'DATETIME';
            }else if(fieldType == Schema.DisplayType.BOOLEAN){
                return 'BOOLEAN';
            }
        
        return null;
    }
}