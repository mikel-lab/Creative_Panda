/**
 * Class TriggerFactory
 *
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 */
global class TriggerFactory
{
    private class TriggerHandlerException extends Exception
    {
    }

    /**
     * Public static method to create and execute a trigger handler
     **
     * @change 08/08/2017 Javier Martínez de Pissón Move Log management to local scope
     * @param Schema.sObjectType soType - Object type to process (SObject.sObjectType)
     * @throws TriggerException if no handler has been coded.
     */
    global static void createHandler(Schema.sObjectType soType)
    {
        Map<String, Trigger_Setup__mdt> mapTriggerSetup = SystemUtils.getTriggerSetup();
        String sObjectName = String.valueOf(soType);

        // Get the Trigger Setup related to the soType
        Trigger_Setup__mdt triggerHandler = mapTriggerSetup.get(sObjectName);

        // Get a handler appropriate to the object being processed. If an error occurs o triggerHandler is null, it throws a TriggerSetupException
        ITrigger handler = getHandler(triggerHandler, sObjectName);

        if(handler != null)
        {
            try
            {
                execute (
                    handler,
                    sObjectName,
                    triggerHandler.Show_Log__c && LogUtil.isDebugMode()
                    );
            }
            catch(Exception except)
            {
                LogUtil.log(except,'TriggerFactory');
            }
        }

    }

    /**
     * Private static method to control the execution of the handler
     **
     * @change 08/08/2017 Javier Martínez de Pissón Move Log management to local scope, as new variables showLog and sObjectName
     * @param ITrigger handler - A Trigger Handler to execute
     * @param sObjectName - Name of the handled sObject
     * @param showLog - Show/Hide the trigger records debug
     */
    private static void execute(ITrigger handler, String sObjectName, Boolean showLog)
    {
        // Before Trigger
        if (Trigger.isBefore)
        {
            if(showLog)
            {
                if(Trigger.NEW != null)
                {
                    String newListTriggerLog = 'START '+ sObjectName +' Trigger Before NEW\n\n';
                    newListTriggerLog += JSON.serializePretty( trigger.NEW, true );
                    LogUtil.debug(newListTriggerLog, LoggingLevel.DEBUG);
                }
                if(Trigger.OLD != null)
                {
                    String oldListTriggerLog = 'START '+ sObjectName +' Trigger Before OLD\n\n';
                    oldListTriggerLog += JSON.serializePretty( trigger.OLD, true );
                    LogUtil.debug(oldListTriggerLog, LoggingLevel.DEBUG);
                }
            }

            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore(trigger.new, trigger.oldMap);

            // Iterate through the records to be inserted passing them to the handler.
            if (Trigger.isInsert)
            {
                LogUtil.debug('START '+ sObjectName +' Before Insert', LoggingLevel.DEBUG);
                handler.beforeInsert(trigger.new);
                LogUtil.debug('END '+ sObjectName +' Before Insert', LoggingLevel.DEBUG);
            }
            // Iterate through the records to be updated passing them to the handler.
            else if (Trigger.isUpdate)
            {
                LogUtil.debug('START '+ sObjectName +' Before Update', LoggingLevel.DEBUG);
                handler.beforeUpdate(trigger.new, trigger.oldMap);
                LogUtil.debug('END '+ sObjectName +' Before Update', LoggingLevel.DEBUG);
            }
            // Iterate through the records to be deleted passing them to the handler.
            else if (Trigger.isDelete)
            {
                LogUtil.debug('START '+ sObjectName +' Before Delete', LoggingLevel.DEBUG);
                handler.beforeDelete(trigger.oldMap);
                LogUtil.debug('END '+ sObjectName +' Before Delete', LoggingLevel.DEBUG);
            }

            if(showLog && Trigger.NEW != null)
            {
                String newListTriggerLog = 'END '+ sObjectName +' Trigger Before NEW\n\n';
                newListTriggerLog += JSON.serializePretty( trigger.NEW, true );
                LogUtil.debug(newListTriggerLog, LoggingLevel.DEBUG);
            }
        }
        else
        {

            if(showLog && Trigger.NEW != null)
            {
                String newListTriggerLog = 'START '+ sObjectName +' Trigger After NEW\n\n';
                newListTriggerLog += JSON.serializePretty( trigger.NEW, true );
                LogUtil.debug(newListTriggerLog, LoggingLevel.DEBUG);
            }

            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter(trigger.new, trigger.oldMap);

            // Iterate through the records inserted passing them to the handler.
            if (Trigger.isInsert)
            {
                LogUtil.debug('START '+ sObjectName +' After Insert', LoggingLevel.DEBUG);
                handler.afterInsert(trigger.new);
                LogUtil.debug('END '+ sObjectName +' After Insert', LoggingLevel.DEBUG);
            }
            // Iterate through the records updated passing them to the handler.
            else if (Trigger.isUpdate)
            {
                LogUtil.debug('START '+ sObjectName +' After Update', LoggingLevel.DEBUG);
                handler.afterUpdate(trigger.new, trigger.oldMap);
                LogUtil.debug('END '+ sObjectName +' After Update', LoggingLevel.DEBUG);
            }
            // Iterate through the records deleted passing them to the handler.dasdas
            else if (Trigger.isDelete)
            {
                LogUtil.debug('START '+ sObjectName +' After Delete', LoggingLevel.DEBUG);
                handler.afterDelete(trigger.oldMap);
                LogUtil.debug('END '+ sObjectName +' After Delete', LoggingLevel.DEBUG);
            }

            // Perform any post processing
            handler.andFinally();

            if(showLog)
            {
                /*String newListTriggerLog = 'END '+ sObjectName +' Trigger After NEW\n\n';
                   newListTriggerLog += JSON.serializePretty( trigger.NEW, true );
                   LogUtil.debug(newListTriggerLog, LoggingLevel.DEBUG);

                   LogUtil.debug('END '+ sObjectName +' Trigger After NEW\n\n', LoggingLevel.DEBUG);*/
            }
        }
    }


    /**
     * Private static method to get the appropriate handler for the object type from the Trigger Setup record
     **
     * @change Javier Martínez de Pissón (15/03/2017) Changed the error handling - Added more detail of the configuration errors
     * @change Javier Martínez de Pissón (08/08/2017) Refactored to improve the log management, using the TriggerSetup__mdt record directly
     * @param triggerHandler - Trigger Handler configured
     * @param sObjectName - Name of the sObject. Used for debuf purposes only
     * @return ITrigger - A trigger handler if one exists or null.
     */
    private static ITrigger getHandler(Trigger_Setup__mdt triggerHandler, String sObjectName)
    {
        if(triggerHandler != null)
        {
            Type handlerClass = null;
            Object handler = null;

            if(triggerHandler.Enable__c)//If the trigger is Enabled
            {
                handlerClass = Type.forName(triggerHandler.DeveloperName);

                if(handlerClass == null)
                {
                    throw new TriggerHandlerException('Handler either not exists or not properly configured - Be sure the class ' + triggerHandler.DeveloperName + ' exists and is defined as global.');
                }

                handler = handlerClass.newInstance();

                if(handler instanceof ITrigger)
                {
                    return (ITrigger) handler;
                }

                throw new TriggerHandlerException('Handler not properly configured - Be sure the class ' + triggerHandler.DeveloperName + ' implements the ITrigger interface.');
            }
            else
            {
                if(Trigger.isBefore) //Only show error log in Before trigger
                {
                    LogUtil.debug('\nAVOIDED '+triggerHandler.DeveloperName+' TRIGGER - NOT ENABLED');
                }
            }

            return null;
        }
        else
        {
            throw new TriggerHandlerException('No Trigger Handler registered for Object Type: ' + sObjectName);
        }
    }
}