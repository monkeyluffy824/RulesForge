export const tokenType = {
    ILLEGAL : 'ILLEGAL',
    COMMA   : 'COMMA',
    RPAREN : 'RPAREN',
    LPAREN : 'LPAREN',
    FUNCTION : 'FUNC',
    EOF: 'EOF',
    FIELD : 'FIELD',
    ARTHEMETIC_OP : 'ARTHEMETIC_OP',
    NULL : 'NULL',
    COMPARISON_OP : 'COMPARISON_OP',
    NUMBER: 'NUMBER',
    STRING: 'STRING',
    BOOLEAN: 'BOOLEAN'
}

class Token{
    constructor(type,literal){
        this.type = type;
        this.literal = literal;
    }
}


class Lexer{
    constructor(input){
        this.input = input;
        this.position =0;
        this.nextPosition =1;
        this.char = input[0] || '';
        this.isCompleted = false;
        this.keywords =['record','oldrecord','null']
    }

    _isComma(){
        return this.char === ',';
    }

    _isWhiteSpace(){
        return this.char === ' ' || this.char === '\t' || this.char === '\n' || this.char === '\r';
    }

    _skipWhitespace() {
        while (this.char === ' ' || this.char === '\t' || this.char === '\n' || this.char === '\r') {
            this._advanceChar()
        }
    }

    _advanceChar(){
        if(this.nextPosition >= this.input.length){
            this.char ='';
            this.isCompleted = true;
        }else{
            this.char = this.input[this.nextPosition];
        }

        this.position = this.nextPosition;
        this.nextPosition = this.nextPosition + 1;
    }

    _isEnd(){
        return this.isCompleted;
    }

    _isNumber(){
        return /^\d$/.test(this.char);
    }

    _isNumberInput(inp){
        return /^\d$/.test(inp);
    }

    _isDecimalPoint(){
        
        if(this.char === '.' && (this.position+1)<this.input.length){
            return this._isNumberInput(this.input[this.position-1]) && this._isNumberInput(this.input[this.position+1]);
        }

        return false;
    }

    _readNumber(){
        let start = this.position;
        let isDecimal = false;
        while(this._isNumber() || this._isDecimalPoint()){
            if(!isDecimal && this._isDecimalPoint()){
                isDecimal = true;
            }else if(isDecimal  && this._isDecimalPoint()){
                return 'ERROR';
            }
            this._advanceChar();
        }
        return this.input?.substring(start,this.position);
    }

    _isMathOp(){
        return ['+','-','*','/'].includes(this.char);
    }

    _isComparisionOp(){
        return ['>','<','=','!'].includes(this.char); // wrong need to implement with various rules
    }

   _readComp(){
        let start = this.position;
        this._advanceChar();
        if((this.input[start] === '=' || this.input[start] === '!' || this.input[start] === '>' || this.input[start] === '<') && this.char === '='){
            this._advanceChar();
            return new Token(tokenType.COMPARISON_OP, this.input.substring(start,this.position));
        }else if(this.input[start] === '>' || this.input[start] === '<'){
            return new Token(tokenType.COMPARISON_OP, this.input[start]);
        }else{
            return new Token(tokenType.ILLEGAL,this.input[start]);
        }   
   } 

    _peek(){
        if(this.nextPosition < this.input.length){
            return this.input[this.nextPosition];
        }else{
            return '';
        }
    }

    _isLparen(){
        return this.char === '(';
    }


    _isRparen(){
        return this.char === ')';
    }

    _isAplha(){
        return /^[a-zA-Z]$/.test(this.char);
    }


    _isSingleQuote(){
        return this.char === "'";
    }

    _readAlpha(){
        let start = this.position;
        while(this._isAplha()){
            this._advanceChar();
        }
        return this.input.substring(start, this.position);
    }

    _readString(){
        let start = this.position;
        let isBlackslash = false;
        let singleQuoteFinsh = false;
        if(this._isSingleQuote()){
            this._advanceChar();
            while((!this._isSingleQuote() || (this._isSingleQuote() && isBlackslash))  &&  !this.isCompleted){
                if(this.char === "\\"){
                    isBlackslash = true;
                }else{
                    isBlackslash = false;
                }
                this._advanceChar();
            }

            if(this._isSingleQuote()){
                singleQuoteFinsh = true;
            }
            if(!this.isCompleted){
                this._advanceChar();
            }
        }    

        return !singleQuoteFinsh ? 'ERROR': this.input.substring(start,this.position);
    }

    _readIdentifier(){
        let start = this.position;
        while(this._isAplha() || this.char === '_' || this.char === '.'){
            this._advanceChar();
        }
        let text = this.input.substring(start,this.position);
        if(this.char === '(' && !this._isNumberInput(this.input[start-1]) && !this.keywords.includes(text.toLowerCase())){
            return new Token(tokenType.FUNCTION,text);
        }else if(text.toLowerCase() === 'true' || text.toLowerCase() === 'false'){
            return new Token(tokenType.BOOLEAN,text);
        }else if(text.toLowerCase() === 'null'){
            return new Token(tokenType.NULL, null);
        }else if(text.toLowerCase().startsWith('record.') || text.toLowerCase().startsWith('oldrecord.')){
            let count = text.split('.').length-1;
            if(count>2 || text[text.length-1] === '.'){
                return new Token(tokenType.ILLEGAL,'ERROR');
            }
            return new Token(tokenType.FIELD,text);
        }else{
            return new Token(tokenType.ILLEGAL, text);
        }
    }

    nextToken(){
        let token = null;

        switch(true){
            case this._isComma():
                token = new Token(tokenType.COMMA, this.char);
                this._advanceChar();
                break;
            case this._isWhiteSpace():
                this._skipWhitespace();
                break;
            case this._isEnd():
                token = new Token(tokenType.EOF,'');
                break;
            case this._isNumber():
                token = new Token(tokenType.NUMBER,this._readNumber());
                break;
            case this._isMathOp():
                token = new Token(tokenType.ARTHEMETIC_OP,this.char);
                this._advanceChar();
                break;
            case this._isComparisionOp():
                token = this._readComp();
                break;
            case this._isLparen():
                token = new Token(tokenType.LPAREN,this.char);
                this._advanceChar();
                break;
            case this._isRparen():
                token = new Token(tokenType.RPAREN,this.char);
                this._advanceChar();
                break;
            case this._isSingleQuote():
                let text = this._readString();
                if(text==='ERROR'){
                    token = new Token(tokenType.ILLEGAL, text);
                }else{
                    token = new Token(tokenType.STRING, text);
                }
                break;
            case this._isAplha():
                token = this._readIdentifier();
                break;
            default :
                token = new Token(tokenType.ILLEGAL, this.char);
                this._advanceChar();
                break;
        }
        return token;
    }
}

class TokenError{
    constructor(message,position){
        this.message = message;
        this.position = position;
    }

    get toString(){
        return `${this.message} at ${this.position}`;
    }
}



export class GetTokens{
    constructor(input){
        this.input = input;
    }

    get tokens(){
        const res=[];
        const lex = new Lexer(this.input);
        while(!lex.isCompleted){
            const nxt = lex.nextToken();
            if(nxt){
                res.push(nxt);
            }
        }

        return res;
    }
}
