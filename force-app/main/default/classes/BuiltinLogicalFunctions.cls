public class BuiltinLogicalFunctions implements Callable{
    public Object call(String action, Map<String,Object> args){
        List<Object> ar = (List<Object>) args.get('args');
        switch on action{
            when 'AND'{
                return evaluateAND(ar);
            }
            when 'OR'{
                return evaluateOR(ar); 
            }
            when 'NOT'{
                return evaluateNOT(ar);
            }
            
            when else{
                throw new AuraHandledException('Unknown function'+action);
            }
        }
    }
    
    private Boolean evaluateAND(List<Object> args){
        isNonNull(args[0],'AND',1);
        isNonNull(args[1],'AND',2);
        return (Boolean) args[0] && (Boolean) args[1];
    }
    
    private Boolean evaluateOR(List<Object> args){
        isNonNull(args[0],'OR',1);
        isNonNull(args[1],'OR',2);
        return (Boolean) args[0] || (Boolean) args[1];
    }
    
    private Boolean evaluateNOT(List<Object> args){
        isNonNull(args[0],'NOT',1);
        return !(Boolean) args[0] ;
    }
    
    private void isNonNull(Object value, String function, Integer pos){
        if(value == null){
            throw new AuraHandledException(function+ 'received null argument at pos:' + pos);
        }
    }
}