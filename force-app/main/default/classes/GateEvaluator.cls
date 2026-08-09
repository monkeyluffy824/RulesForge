public class GateEvaluator {
	
    public static Boolean checkAllGates(RuleDefinition rule, System.TriggerOperation operation){
        if(rule == null){
            throw new AuraHandledException('rule is null');
        }
        
        return checkOperationType(rule,operation);
        
    }
    
    private static Boolean checkOperationType(RuleDefinition rule, System.TriggerOperation operation){
        if(operation == TriggerOperation.BEFORE_INSERT){
            return rule.executeBeforeInsert;
        }else if(operation == TriggerOperation.BEFORE_UPDATE){
            return rule.executeBeforeUpdate;
        }else if(operation == TriggerOperation.BEFORE_DELETE){
            return rule.executeBeforeDelete;
        }
        
        return false;
    }
}