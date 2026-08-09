public class BuiltinStringFunctions implements Callable{
    public Object call(String action, Map<String,Object> args){
        List<Object> ar = (List<Object>) args.get('args');
        switch on action{
            when 'CONTAINS'{
                return evaluateContains(ar);
            }
            when 'STARTSWITH'{
                return evaluateStartsWith(ar);
            }
            when 'LEN'{
                return evaluateLength(ar);
            }
            when 'REGEX'{
                return evaluateRegex(ar);
            }
            when else{
                throw new AuraHandledException('Unknown function'+action);
            }
        }
    }
    
    private Boolean evaluateContains(List<Object> args){
        isNonNull(args[0],'CONTAINS',1);
        String str = (String) args[0];
        String chk = (String) args[1];
        return str.containsIgnoreCase(chk);
    }
    
    private Boolean evaluateStartsWith(List<Object> args){
        isNonNull(args[0],'STARTSWITH',1);
        String str = (String) args[0];
        String pfx = (String) args[1];
        return str.startsWithIgnoreCase(pfx);
    }
    
    private Decimal evaluateLength(List<Object> args){
        isNonNull(args[0],'LEN',1);
        String str = (String) args[0];
        return Decimal.valueOf(str.length());
    }
    
    private Boolean evaluateRegex(List<Object> args){
        isNonNull(args[0],'REGEX',1);
        isNonNull(args[1],'REGEX',2);
        String regex = (String) args[0];
        String strCmp = (String) args[1];
        return Pattern.matches(regex,strCmp);
    }
    
    
    private void isNonNull(Object value, String function, Integer pos){
        if(value == null){
            throw new AuraHandledException(function+ 'received null argument at pos:' + pos);
        }
    }
}