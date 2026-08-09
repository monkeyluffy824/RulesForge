public class RuleDefinition {
	public String developerName;
    public String objectApiName;
    public String expression;
    public String astJson;
    public String errorMessage;
    public Boolean isActive;
    public Integer executionOrder;
    public Boolean hasParentFields;
    public ASTNode astRoot;
    
    public Boolean executeBeforeInsert;
    public Boolean executeBeforeDelete;
    public Boolean executeBeforeUpdate;
    
    
    public RuleDefinition(RuleEngine_Rule__mdt rule){
        this.developerName = rule.DeveloperName;
        this.objectApiName = rule.Object_API_Name__c;
        this.expression = rule.Expression__c;
        this.errorMessage = rule.Error_Message__c;
        this.isActive = rule.Is_Active__c;
        this.executionOrder = (Integer) rule.Execution_Order__c;
        this.hasParentFields = rule.Has_Parent_Fields__c;
        this.executeBeforeInsert = rule.Execute_Before_Insert__c;
        this.executeBeforeUpdate = rule.Execute_Before_Update__c;
        this.executeBeforeDelete = rule.Execute_Before_Delete__c;
        this.astJson = reassembleChunks(rule);
    }
    
    
    private String reassembleChunks(RuleEngine_Rule__mdt rule){
        String ast = '';
        if(!String.isBlank(rule.AST_Chunk_1__c)){
            ast += rule.AST_Chunk_1__c;
        }
        
        if(!String.isBlank(rule.AST_Chunk_2__c)){
            ast += rule.AST_Chunk_2__c;
        }
        
        if(!String.isBlank(rule.AST_Chunk_3__c)){
            ast += rule.AST_Chunk_3__c;
        }
        
        if(!String.isBlank(rule.AST_Chunk_4__c)){
            ast += rule.AST_Chunk_4__c;
        }
        
        if(!String.isBlank(rule.AST_Chunk_5__c)){
            ast += rule.AST_Chunk_5__c;
        }
        
        
        return ast;
        
    }
    
}