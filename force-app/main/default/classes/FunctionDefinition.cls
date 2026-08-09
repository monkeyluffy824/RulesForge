public class FunctionDefinition {
	public String functionName;
    public String className;
    public Integer argumentCount;
    public String returnType;
    public Boolean isBuiltIn;
    public Boolean isActive;
    
    public FunctionDefinition(RuleEngine_Function__mdt fun){
        this.functionName = fun.Function_Name__c;
        this.className = fun.Class_Name__c;
        this.argumentCount = (Integer) fun.Argument_Count__c;
        this.returnType = fun.Return_Type__c;
        this.isBuiltIn = fun.Is_Built_In__c;
        this.isActive = fun.Is_Active__c;
    }
}