public class BuiltinNullFunctions implements Callable{
	public Object call(String action, Map<String,Object> args){
        List<Object> ar = (List<Object>) args.get('args');
        switch on action{
            when 'ISBLANK'{
                return evaluateIsBlank(ar);
            }
            when 'ISNOTNULL'{
                return evaluateIsNotNull(ar);
            }
            when 'NVL_NUMBER'{
                return nullDefaultNumber(ar);
            }
            when 'NVL_STRING'{
                return nullDefaultString(ar);
            }
            when 'NVL_BOOLEAN'{
                return nullDefaultBoolean(ar);
            }
            when 'NVL_DATE'{
                return nullDefaultDate(ar);
            }
            when 'NVL_DATETIME'{
                return nullDefaultDateTime(ar);
            }
            when else{
                throw new AuraHandledException('Unknown function'+action);
            }
        }
    }
    
    private Boolean evaluateIsBlank(List<Object> args){
        if(args[0] == null){
            return true;
        }
        if(args[0] instanceOf String){
            return String.isBlank((String) args[0]);
        }
        return false;
    }
    
    
    
    private Boolean evaluateIsNotNull(List<Object> args){
        if(args[0] == null){
            return false;
        }
        
        return true;
    }
    
    private Decimal nullDefaultNumber(List<Object> args){
        if(args[0] == null){
            return (Decimal) args[1];
        }
        
        return (Decimal) args[0];
    }
    
    private String nullDefaultString(List<Object> args){
        if(args[0] == null){
            return (String) args[1];
        }
        
        return (String) args[0];
    }
    
    private Boolean nullDefaultBoolean(List<Object> args){
        if(args[0] == null){
            return (Boolean) args[1];
        }
        
        return (Boolean) args[0];
    }
    
    private Date nullDefaultDate(List<Object> args){
        if(args[0] == null){
            return (Date) args[1];
        }
        
        return (Date) args[0];
    }
    
    private DateTime nullDefaultDateTime(List<Object> args){
        if(args[0] == null){
            return (DateTime) args[1];
        }
        
        return (DateTime) args[0];
    }
    
    
}