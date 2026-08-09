public class ValidationResult {
	public Boolean isValid;
    public String errorMessage;
    
    public ValidationResult(Boolean isValid){
        this.isValid = isValid;
    }
    
    public ValidationResult(Boolean isValid, String errorMessage){
        this.isValid = isValid;
         this.errorMessage = errorMessage;
    }
}