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

import ballerina/http;

# Represents a Graphql listener endpoint.
public class Listener {
    private http:Listener httpListener;
    private HttpService httpService;
    private Engine engine;

    # Invoked during the initialization of a `graphql:Listener`. Either an `http:Listner` or a port number must be
    # provided to initialize the listener.
    #
    # + listenTo - An `http:Listener` or a port number to listen for the GraphQL service
    public isolated function init(int|http:Listener listenTo) returns ListenerError? {
        if (listenTo is int) {
            http:Listener|error httpListener = new(listenTo);
            if (httpListener is error) {
                return error ListenerError("Listener initialization failed", httpListener);
            } else {
                self.httpListener = httpListener;
            }
        } else {
            self.httpListener = listenTo;
        }
        // TODO: Decouple engine and the listener
        self.engine = new(self);
        self.httpService = new(self.engine);
    }

    # Attaches the provided service to the Listener.
    #
    # + s - The `graphql:Service` object to attach
    # + name - The path of the service to be hosted
    # + return - A `graphql:ListenerError`, if an error occurred during the service attaching process, otherwise nil
    public isolated function attach(Service s, string[]|string? name = ()) returns ListenerError? {
        error? result = self.httpListener.attach(self.httpService, name);
        if (result is error) {
            return error ListenerError("Error occurred while attaching the service", result);
        }
        self.engine.registerService(s);
    }

    # Detaches the provided service from the Listener.
    #
    # + s - The service to be detached
    # + return - A `graphql:ListenerError`, if an error occurred during the service detaching process, otherwise nil
    public isolated function detach(Service s) returns ListenerError? {
        error? result = self.httpListener.detach(self.httpService);
        if (result is error) {
            return error ListenerError("Error occurred while detaching the service", result);
        }
    }

    # Starts the attached service.
    #
    # + return - A `graphql:ListenerError`, if an error occurred during the service starting process, otherwise nil
    public isolated function 'start() returns ListenerError? {
        error? result = self.httpListener.'start();
        if (result is error) {
            return error ListenerError("Error occurred while starting the service", result);
        }
    }

    # Gracefully stops the graphql listener. Already accepted requests will be served before the connection closure.
    #
    # + return - A `graphql:ListenerError`, if an error occurred during the service stopping process, otherwise nil
    public isolated function gracefulStop() returns ListenerError? {
        error? result = self.httpListener.gracefulStop();
        if (result is error) {
            return error ListenerError("Error occurred while stopping the service", result);
        }
    }

    # Stops the service listener immediately. It is not implemented yet.
    #
    # + return - A `graphql:ListenerError`, if an error occurred during the service stopping process, otherwise nil
    public isolated function immediateStop() returns ListenerError? {
        error? result = self.httpListener.immediateStop();
        if (result is error) {
            return error ListenerError("Error occurred while stopping the service", result);
        }
    }
}
