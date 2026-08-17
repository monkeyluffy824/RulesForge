**RulesForge** - **A Design Learning Project** - **Prototype**

**RulesForge** is a dynamic metadata-driven validation rule engine for salesforce with a custom domain specific expression language.
It is an attempt to create a custom expression language designed specifically for boolean validation logic, which can be interpretated and executed in apex. RulesForge is not a complete upgrade to native validation rule engine, rather an alternative with upgrades as well as limitations. 

**Why this Exists**

**RulesForge** is a complete, working implementation of a small programming language- it has its own tokenizer, recursive descent parser with operator precedence, a typed AST, a schema Driven Type Checker and an iterative (non-recursive) execution engine. There are no third party libraries used, everything is written in Salesforce Apex and javaScript. It was built primarily as a learning project to go deep on compiler/interpreter fundamentals and also on salesforce governer limits, heap size, apex etc. 

