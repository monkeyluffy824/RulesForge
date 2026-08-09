global class TriggerHandler {
	private static Set<String> executingObjects = new Set<String>();
    
    global static void execute(String objectName, List<SObject> records, Map<Id,SObject> oldMap, System.TriggerOperation operation){
        if(records == null || records.isEmpty()){
            return;
        }
        
        if(executingObjects.contains(objectName)){
            return;
        }
        
        executingObjects.add(objectName);
        try{
            executeInternal(objectName,records,oldMap,operation);
        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());
        }finally{
            executingObjects.remove(objectName);
        }
    }
    
    private static void executeInternal(String objectName, List<SObject> records, Map<Id,SObject> oldMap, System.TriggerOperation operation){
        List<RuleDefinition> rules = RuleEngineCache.getRulesForObject(objectName);
        if(rules.isEmpty()){
            return;
        }
        List<RuleDefinition> passingRules = ruleGateChecks(rules,operation);
        
        if(passingRules.isEmpty()){
            return;
        }
        
        checkForInsert(passingRules,operation);
        
        Map<String,ASTNode> deserializeAST = deserializeRules(passingRules);

        Map<Id,SObject> parentFields = enrichRecordsIfNeeded(passingRules,deserializeAST,objectName,records);

        executeRules(passingRules,deserializeAST,records,oldMap,parentFields);
        
    }
    
    private static List<RuleDefinition> ruleGateChecks(List<RuleDefinition> rules, System.TriggerOperation operation){
        List<RuleDefinition> passingRules = new List<RuleDefinition>();
        for(RuleDefinition rule: rules){
            if(GateEvaluator.checkAllGates(rule,operation)){
                passingRules.add(rule);
            }
        }
        
        return passingRules;
    }

    private static Map<String,ASTNode> deserializeRules(List<RuleDefinition> rules){
        Map<String,ASTNode> result = new Map<String,ASTNode>();
        for(RuleDefinition rule: rules){
            ASTNode root = ASTDeserializer.deserializeString(rule.astJson);
            result.put(rule.developerName, root);
        }

        return result;
    }
    
    private static void checkForInsert(List<RuleDefinition> rules,System.TriggerOperation operation){
        List<RuleDefinition> rulesToRemove = new List<RuleDefinition>();
        if(operation == TriggerOperation.BEFORE_INSERT ){
            for(RuleDefinition rule: rules){
                if(rule.hasParentFields){
                    rulesToRemove.add(rule);
                }
            }

             for(RuleDefinition rule: rulesToRemove){
                rules.remove(rules.indexOf(rule));
             }
            
        }
    }

    private static Map<Id,SObject> enrichRecordsIfNeeded(List<RuleDefinition> rules,Map<String,ASTNode> deserializeAST, String objectName, List<SObject> records){
        Boolean isEnrichmentRequired = false;
        for(RuleDefinition rule: rules){
            if(rule.hasParentFields){
                isEnrichmentRequired = true;
                break;
            }
        }

        if(!isEnrichmentRequired){
            return null;
        }

        List<String> parentFields = new List<String>();

        for(RuleDefinition rule: rules){
            if(rule.hasParentFields){
                ASTNode node = deserializeAST.get(rule.developerName);
                FieldResolver.collectParentFields(node,parentFields);
            }
        }

        Set<Id> recordIds = new Map<Id,SObject>(records).keySet();
        

        return FieldResolver.enrichRecords(objectName,new Set<String>(parentFields),recordIds);
    }

    private static void executeRules(List<RuleDefinition> rules,Map<String,ASTNode> deserializeAST,List<SObject> records,Map<Id,SObject> oldMap,Map<Id,SObject> parentFields){
        Map<String,FunctionDefinition> functionRegistry = RuleEngineCache.getFunctionRegistory();
        ASTExecutor executor = new ASTExecutor(functionRegistry);
        for(RuleDefinition rule:rules){
            ASTNode root = deserializeAST.get(rule.developerName);
            for(Sobject record: records){
                SObject enrichedNewRecord = rule.hasParentFields ? parentFields.get(record.Id):null;
                SObject oldRecord = oldMap != null ? oldMap.get(record.Id): null;
                ValidationResult result;
                try{
                    result = executor.execute(root,record,oldRecord,enrichedNewRecord);
                }catch(Exception e){
                    record.addError('Error Occured in Processing rules');
                    continue;
                }
                if(result.isValid){
                    record.addError(rule.errorMessage);
                }
            }

            deserializeAST.put(rule.developerName,null);
        }
    }
}