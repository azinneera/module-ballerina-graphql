// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import graphql.parser;

# Represents the Ballerina GraphQL engine.
public class Engine {
    private Listener 'listener;
    private __Schema? schema;
    private Service? graphqlService;

    public isolated function init(Listener 'listener) {
        self.'listener = 'listener;
        self.schema = ();
        self.graphqlService = ();
    }

    isolated function getOutputObjectForQuery(string documentString, string operationName) returns OutputObject {
        parser:DocumentNode|OutputObject result = self.parse(documentString);
        if (result is OutputObject) {
            return result;
        }
        parser:DocumentNode document = <parser:DocumentNode>result;
        var validationResult = self.validateDocument(document);
        if (validationResult is OutputObject) {
            return validationResult;
        } else {
            if (document.getOperations().length() == 1) {
                return self.execute(document.getOperations()[0]);
            }
            foreach parser:OperationNode operationNode in document.getOperations() {
                if (operationName == operationNode.getName()) {
                    return self.execute(operationNode);
                }
            }
            string name = operationName == parser:ANONYMOUS_OPERATION ? "" : operationName;
            string message = "Operation \"" + name + "\" is not present in the provided GraphQL document.";
            ErrorDetail errorDetail = {
                message: message,
                locations: []
            };
            return getOutputObjectFromErrorDetail(errorDetail);
        }
    }

    isolated function registerService(Service s) {
        self.graphqlService = s;
        self.schema = createSchema(s);
        self.populateSchemaType();
    }

    isolated function parse(string documentString) returns parser:DocumentNode|OutputObject {
        parser:Parser parser = new (documentString);
        parser:DocumentNode|parser:Error parseResult = parser.parse();
        if (parseResult is parser:DocumentNode) {
            return parseResult;
        }
        ErrorDetail errorDetail = getErrorDetailFromError(<parser:Error>parseResult);
        return getOutputObjectFromErrorDetail(errorDetail);
    }

    isolated function validateDocument(parser:DocumentNode document) returns OutputObject? {
        if (self.schema is __Schema) {
            ValidatorVisitor validator = new(<__Schema>self.schema);
            validator.validate(document);
            ErrorDetail[] errors = validator.getErrors();
            if (errors.length() > 0) {
                return getOutputObjectFromErrorDetail(errors);
            }
        } else {
            ErrorDetail errorDetail = {
                message: "Internal Error: GraphQL Schema is not present.",
                locations: []
            };
            return getOutputObjectFromErrorDetail(errorDetail);
        }
    }

    isolated function execute(parser:OperationNode operationNode) returns OutputObject {
        if (self.graphqlService is ()) {
            ErrorDetail errorDetail = {
                message: "Internal Error: GraphQL service is not available.",
                locations: []
            };
            return getOutputObjectFromErrorDetail(errorDetail);
        }
        Service s = <Service>self.graphqlService;
        ExecutorVisitor executor = new(s, <__Schema>self.schema);
        OutputObject outputObject = executor.getExecutorResult(operationNode);
        return outputObject;
    }

    isolated function populateSchemaType() {
        __Schema schema = <__Schema>self.schema;
        __Type schemaType = {
            kind: OBJECT,
            name: SCHEMA_TYPE_NAME
        };

        __Type typesType = {
            kind: NON_NULL,
			name: (),
			ofType: <__Type>schema.types[TYPE_TYPE_NAME]
        };
        map<__Field> fields = {};
        __Field typesField = {
            name: TYPES_FIELD,
            'type: typesType
        };
        fields[TYPES_FIELD] = typesField;
        schemaType.fields = fields;
        schema.types[SCHEMA_TYPE_NAME] = schemaType;
    }
}
