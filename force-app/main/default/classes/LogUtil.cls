/**
 * Class with all the utilities for the debug of the code and the log generation.
 *
 * @author Asier Rodríguez
 * @date 08/08/2016
 **/
global virtual class LogUtil
{

    public static Map<String,String> getLogSetup
    {
        get
        {
            if(getLogSetup == null)
            {
                getLogSetup = new Map<String,String>();
                for(LogSetup__mdt nextMDT : [SELECT DeveloperName, Value__c FROM LogSetup__mdt])
                {
                    getLogSetup.put(nextMDT.DeveloperName,nextMDT.Value__c);
                }
            }
            return getLogSetup;
        }
        private set;
    }

    //#region Config enums
    global enum LoggingMode { ALL, SILENT, DISABLED }
    // TODO - Crear buena lista de tipo y subtipo de registro de eventos
    private enum LogType {EXCEPTIONTYPE, BATCH, WEB_SERVICE, QUEUE, JOB, DEBUGDUMP, UNDEFINED, DATABASE_ERROR}
    private enum LogSubType {VALIDATION_RULE, REQUIRED_FIELD_MISSING, TIMEOUT, UNDEFINED, STRING_TOO_LONG}
    //#endregion

    //#region Attributes

    @TestVisible private static Map<String, Integer> eventFieldLenghtDescription = new Map<String,Integer>{'text'=>255,'id'=>18,'long'=>131072};

    //@TestVisible private static List<Error_Log__c> exceptionList = new List<Error_Log__c>();     //All the debug logs saved by the user.
    @TestVisible private static Logger debugLogger = new Logger();

    @testVisible private static Boolean logEnabled = null;
    @testVisible private static Boolean debugEnabled = null;
    private enum LoggingType { ONLY_MESSAGE, MESSAGE_AND_OBJECT }
    @TestVisible private static Log__e logEvent = new Log__e();
    //#endregion

    //#region (\(O.O)/) Client Log Class Definition(\(O.O)/)

    /**
     * Debug writer instance. Must be a client org class; if not, the System debugs would not been shown
     * because they own to the manage package context.
     * Uses Singleton pattern and static initialization, to improve perfomance.
     *
     * @author Javier Martinez de Pissón
     * @date 10/08/2016
     */
    private final static LogUtil clientLogInstance;
    static
    {
        Type logClassType = Type.forName(SystemUtils.getSystemSetup('LogClass'));

        // Throw an exception is the class is not found.
        // The client class must be Global
        if(logClassType == null)
        {
            throw new SystemSetupException('Error handling LogUtil. System setup LogClass either not properly configured or unconfigured - Be sure the class exists, inherits from LogUtil and is configured as global.');
        }

        clientLogInstance = (LogUtil)logClassType.newInstance();

    }
    //#endregion

    //#region (\(O.O)/) Debug Log Aux Functions (\(O.O)/)


    /**
     * Debug writer method. Must be overriden by the child class which inherits from LogUtil
     *
     * @author Javier Martinez de Pissón
     * @date 10/08/2016
     */
    global virtual void writeDebug(LoggingLevel debugLevel, String message)
    {
    }

    /**
     * Debug writer. It only writes in the debug when the code is running in Sandbox or the flag of force log is true.
     * This method is private because the users will call to the public overloads of this method.
     **
     * @author Asier Rodríguez
     * @date 08/08/2016
     * @change 08/08/2017 Javier Martinez de Pissón Added log mode management.
     */
    private static void debug(String debugMessage, Object debugObject, LoggingLevel debugLevel, LoggingType logType)
    {
        if(isLogEnabled())
        {
            debugLogger.log(debugLevel, debugMessage, debugObject);

            if(logType == LoggingType.ONLY_MESSAGE)
            {
                clientLogInstance.writeDebug(debugLevel, '##NTS DEBUG## '+ debugMessage);
            }
            else if (logType == LoggingType.MESSAGE_AND_OBJECT)
            {
                clientLogInstance.writeDebug(debugLevel, '##NTS DEBUG## ' + debugMessage +' Object:\n' + JSON.serializePretty( debugObject, true ));
            }
            else
            {
                throw new SystemSetupException('LoggingType not found');
            }
        }
        else if(isDebugMode())
        {
            debugLogger.log(debugLevel, debugMessage, debugObject);
        }
    }

    /**
     * Debug writer overload with only a String.
     *
     * @author Asier Rodríguez
     * @date 08/08/2016
     */
    global static void debug(String message)
    {
        LogUtil.debug(message, null, LoggingLevel.DEBUG, LoggingType.ONLY_MESSAGE);
    }

    /**
     * Debug writer overload with a String and the debug level.
     *
     * @author Asier Rodríguez
     * @date 08/08/2016
     */
    global static void debug(String message, LoggingLevel debugLevel)
    {
        LogUtil.debug(message, null, debugLevel, LoggingType.ONLY_MESSAGE);
    }

    /**
     * Debug writer overload with a String and an Object
     *
     * @author Asier Rodríguez
     * @date 08/08/2016
     */
    global static void debug(String message, Object sfObject)
    {
        LogUtil.debug(message, sfObject, LoggingLevel.DEBUG, LoggingType.MESSAGE_AND_OBJECT);
    }

    /**
     * Debug writer overload with a String, an Object and the debug level.
     *
     * @author Asier Rodríguez
     * @date 08/08/2016
     */
    global static void debug(String message, Object sfObject, LoggingLevel debugLevel)
    {
        LogUtil.debug(message, sfObject, debugLevel, LoggingType.MESSAGE_AND_OBJECT);
    }
    //#endregion

    //#region (\(O.O)/) Other Functions (\(O.O)/)

    /**
     * Will return true if the log is enabled in the System setup custom setting.
     * If there is no custom setting, the log will be always disabled.
     **
     * @author Asier Rodríguez
     * @date 08/08/2016
     * @change Javier Martínez de Pissón (15/03/2017) Changed isNotBlank for isNotEmpty - Verifies also null value
     * @change Javier Martínez de Pissón (28/08/2017) The assigned value is only a default value. It can be changed later.
     */
    public static Boolean isLogEnabled()
    {
        if(logEnabled == null)
        {
            String logMode = SystemUtils.getSystemSetup('LogMode');

            logEnabled = (String.isNotEmpty(logMode) && logMode == '2') || SystemUtils.isRunningInSandbox();

            if(logEnabled)
            {
                debugEnabled = true;
            }
        }

        return logEnabled;
    }

    /**
     * Will return true if the debug mode is enabled in the System setup custom setting, or we are running in Sandbox
     * Can be changed with the method setLogMode
     **
     * @author Asier Rodríguez
     * @date 08/08/2016
     * @change Javier Martínez de Pissón (15/03/2017) Changed isNotBlank for isNotEmpty - Verifies also null value
     * @change Javier Martínez de Pissón (28/08/2017) The assigned value is only a default value. It can be changed later.
     */
    public static Boolean isDebugMode()
    {
        if(debugEnabled == null)
        {
            String logMode = SystemUtils.getSystemSetup('LogMode');

            debugEnabled = (String.isNotEmpty(logMode) && (logMode == '1' || logMode == '2')) || SystemUtils.isRunningInSandbox();
        }

        return debugEnabled;
    }

    /**
     * Allows to change the log mode programatically, using the enum LoggingMode
     * <ul>
     *     <li>LogUtil.LoggingMode.ALL => Save/output debug</li>
     *     <li>LogUtil.LoggingMode.DEBUG_ONLY => Save debug</li>
     *     <li>LogUtil.LoggingMode.OFF => Debug mode off. Saves heap</li>
     * </ul>
     **
     * @author  Javier Martínez de Pissón (15/03/2017)
     * @date 08/08/2016
     * @change Javier Martínez de Pissón (15/03/2017) Changed isNotBlank for isNotEmpty - Verifies also null value
     */
    global static void setLogMode(LoggingMode logMode)
    {
        if(logMode == LoggingMode.ALL)
        {
            logEnabled = true;
            debugEnabled = true;
        }
        else if(logMode == LoggingMode.SILENT)
        {
            logEnabled = false;
            debugEnabled = true;
        }
        else
        {
            logEnabled = false;
            debugEnabled = false;
        }
    }


    //#endregion
    //#endregion

    //#region (\(O.O)/) Private Auxiliar Classes (\(O.O)/)
    private class SystemSetupException extends Exception
    {
    }


    /**
     * Logger Class
     **
     * @author Javier Martínez de Pissón
     * @date 08/08/2017
     * *
     * @modification    jgallaga
     * @date            14/09/2020
     * @description
     *                  Changed the place for the line break to append it only when there are still more entries
     */
    @TestVisible private class Logger
    {
        //#region Attributes
        private DebugLogEntry[] entries;
        //#endregion

        Logger()
        {
            this.entries = new DebugLogEntry[] {};
        }

        //#region Methods
        public void log(LoggingLevel debugLevel, String debugMessage, Object debugObject)
        {
            this.entries.add(new DebugLogEntry(debugLevel, debugMessage, debugObject));
        }

        public String getLog()
        {
            String logText = '';

            while(!this.entries.isEmpty())
            {
                logText += this.entries.remove(0).toString();
            }

            // [14/09/2020 - jgallaga] Add the line break only if there are more entries
            logText += this.entries.isEmpty() ? '' : '\r\n';

            return logText;
        }

        public void clear()
        {
            this.entries.clear();
        }

        //#endregion
    }


    private class DebugLogEntry
    {
        private LoggingLevel entryDebuggedLevel;
        private Object entryDebuggedObject;
        private String entryDebuggedMessage;

        public DebugLogEntry(LoggingLevel debugLevel, String debugMessage, Object debugObject)
        {
            this.entryDebuggedLevel = debugLevel;
            this.entryDebuggedObject = debugObject;
            this.entryDebuggedMessage = debugMessage;
        }

        public override String toString()
        {
            if(entryDebuggedObject == null)
            {
                return entryDebuggedLevel + ': '+ entryDebuggedMessage;
            }

            return entryDebuggedLevel + ': '+ entryDebuggedMessage + '\r\nObject: ' + JSON.serialize(entryDebuggedObject, true);
        }
    }

    //@region main event methods

    /**
     * The event publishing method. Just launch the received event!
     *
     * @author      jgallaga
     * @date        08/09/2020
     * @description
     *              Mehotd to send the event to the Event Bus
     * @param       event - The Log Event to be sent
     */
    private static void publish()
    {
        if(logEvent != null && getLogSetup.containsKey('LogMode') && getLogSetup.get('LogMode') == '1')
        {
            Database.saveResult publishResult = Eventbus.publish(logEvent);
            // TODO - Que gestionar del save result, ¿se puede recibir algun pete? ¿tonteria hacer saveresult?
        }
    }

    /**
     * The final step to publish an event.
     * *
     * @author      jgallaga
     * @date        08/09/2020
     * @description
     *              Transforms the received data into a Log event to be published
     *              The String field lenght of the event is checked to prevent errors
     * @param       exceptionLine - The line where the error happened
     * @param       throwingTime - Date/Time of exception, the moment it happened
     * @param       stackTraceString - Additional exception data, the execution order that throws the exception
     * @param       customMessage - The message can be one written by a custom exception, a dump of DMLException errors or the exception message.
     * @param       className - Class Name from where the log was called
     * @param       relatedTo - If not null, the existing record or process Id
     * @param       logType - Additional info of the type of log.
     * @param       subType - One word description of the log subtype. For example the reason of the exception
     */
    private static void log
    (   String exceptionLine, DateTime throwingTime, String stackTraceString,
        String customMessage, String className, String relatedTo, String logType, LogSubType pLogSubType)
    {
        //pLogType = pLogType != null ?  pLogType : LogType.UNDEFINED;
        pLogSubType = pLogSubType  != null ? pLogSubType : LogSubType.UNDEFINED;

        logEvent = new Log__e
        (
            CausedBy__c               = Userinfo.getUserId(), // El usuario que ha lanzado el evento
            ThrowingTime__c           = throwingTime != null ? throwingTime : System.now(), // TODO - obtener el GMT del cliente para que la hora sea correcta ?
            LogSubtype__c             = pLogSubType.name()
        );

        // For each String field, check the char limit is not reached
        String tempString;

        tempString = String.isNotBlank(logType) ? logType : '';
        logEvent.LogType__c = tempString.left(eventFieldLenghtDescription.get('text'));

        tempString = String.isNotBLank(exceptionLine) ? exceptionLine : '';
        logEvent.ExceptionLine__c = tempString.left(eventFieldLenghtDescription.get('text'));

        tempString = String.isNotBlank(className) ? className : '';
        logEvent.ThrowingClass__c = tempString.left(eventFieldLenghtDescription.get('text'));

        tempString = String.isNotBlank(relatedTo) ? relatedTo : '';
        logEvent.RelatedTo__c = tempString.left(eventFieldLenghtDescription.get('id'));

        tempString = String.isNotBlank(customMessage) ? customMessage : '';
        logEvent.ExceptionMessage__c = tempString.right(eventFieldLenghtDescription.get('long'));

        tempString = String.isNotBlank(stackTraceString) ? stackTraceString : '' ;
        logEvent.ExceptionStackTrace__c = tempString.right(eventFieldLenghtDescription.get('long'));

        logEvent.Debug__c = debugLogger.getLog().right(eventFieldLenghtDescription.get('long'));

        publish();
    }

    //#endregion


    //#region Exception logging methods

    /**
     * The public method that allows to publish the exception information as an event
     * *
     * @author      jgallaga
     * @date        09/09/2020
     * @description
     *
     * @param       e - The Exception to be sent to the event
     */
    global static void log(Exception e)
    {
        try
        {
            log(String.valueOf(e.getLineNumber()), System.now(), e.getStackTraceString(),e.getMessage(), null, null, e.getTypeName(), LogSUbType.UNDEFINED );
        }
        catch(Exception error)
        {
            throw error;
        }
    }

    /**
     * The public method that allows to publish the exception information as an event
     * with the class name
     * *
     * @author      jgallaga
     * @date        09/09/2020
     * @description
     *              If the exception arrives as null, don't log. When Winter '21 arrives it can be changed
     *              so it calls with null values.
     * @param       e - The Exception to be sent to the event
     * @param       className - The class from where the log was called
     */
    global static void log(Exception e, String className)
    {
        try
        {
            // FIXME - Winter '21 e.?getLineNumber... Prevents the try catch
            log(String.valueof(e.getLineNumber()), System.now(),e.getStackTraceString(), e.getMessage(), className, null, e.getTypeName(), LogSubType.UNDEFINED);
        }
        catch(Exception nullExceptionError)
        {
            throw nullExceptionError; // If you send a null Exception, bad boy
        }
    }

    /**
     * The public method that allows to publish the exception information as an event
     * wih the class name and the Id that was involved with it
     * *
     * @author      jgallaga
     * @date        09/09/2020
     * @description
     *              Checks if the exception is of DML type, if so, obtains the data as
     *              a String to be sent in the message field
     * @param       e - The Exception to be sent to the event
     * @param       className - The class from where the log was called
     * @param       relatedTo - Id of a record, job, etc related to the exception
     */
    global static void log(Exception e, String className, String relatedTo)
    {
        // FIXME - Winter '21 e.?getLineNumber... Prevents the try catch
        try
        {
            log(String.valueof(e.getLineNumber()), System.now(),e.getStackTraceString(), e.getMessage(), className, relatedTo, e.getTypeName(), LogSubType.UNDEFINED);
        }
        catch(Exception error)
        {
            throw error;
        }
    }

    //#endregion

    //#region DMLException logging method

    /**
     * The public method that allows to publish the exception information as an event
     * wih the class name and the Id that was involved with it
     * *
     * @author      jgallaga
     * @date        10/09/2020
     * @description
     *              Checks if the exception is of DML type, if so, obtains the data as
     *              a String to be sent in the message field
     * @param       dmlEx - The DMLException to be sent to the event
     */
    global static void log(DMLException dmlEx)
    {
        // FIXME - Winter '21 e.?getLineNumber... Prevents the try catch
        try
        {
            log(String.valueOf(dmlEx.getLineNumber()), System.now(), dmlEx.getStackTraceString(), dmlExceptionString(dmlEx) ,null, null, dmlEx.getTypeName(), LogSubType.UNDEFINED);
        }
        catch(Exception error)
        {
            throw error;
        }
    }


    /**
     * The public method that allows to publish the exception information as an event
     * wih the class name and the Id that was involved with it
     * *
     * @author      jgallaga
     * @date        10/09/2020
     * @description
     *              Checks if the exception is of DML type, if so, obtains the data as
     *              a String to be sent in the message field
     * @param       e - The DMLException to be sent to the event
     * @param       className - The class from where the log was called
     */
    global static void log(DMLException dmlEx, String className)
    {
        // FIXME - Winter '21 e.?getLineNumber... Prevents the try catch
        try
        {
            log(String.valueOf(dmlEx.getLineNumber()), System.now(), dmlEx.getStackTraceString(), dmlExceptionString(dmlEx), className, null, dmlEx.getTypeName(), LogSubType.UNDEFINED);
        }
        catch(Exception error)
        {
            throw error;
        }
    }


    /**
     * The public method that allows to publish the exception information as an event
     * wih the class name and the Id that was involved with it
     * *
     * @author      jgallaga
     * @date        10/09/2020
     * @description
     *              Checks if the exception is of DML type, if so, obtains the data as
     *              a String to be sent in the message field
     * @param       e - The DMLException to be sent to the event
     * @param       className - The class from where the log was called
     * @param       relatedTo - Id of a record, job, etc related to the exception
     */
    global static void log(DMLException dmlEx, String className, String relatedTo)
    {
        // FIXME - Winter '21 e.?getLineNumber... Prevents the try catch
        try
        {
            log(String.valueOf(dmlEx.getLineNumber()), System.now(), dmlEx.getStackTraceString(), dmlExceptionString(dmlEx), className, relatedTo, dmlEx.getTypeName(), LogSubType.UNDEFINED);
        }
        catch(Exception e)
        {
            throw e;
        }
    }

    //#endregion

    //#region loggin Database.errors

    /**
     * The public method that allows to publish the DML Database error information as an event
     * *
     * @author      jgallaga
     * @date        10/09/2020
     * @description
     *              Obtains the data of the errors into a String to be sent in the message field
     * @param       error - The Database.Error from a DML
     */
    global static void log(List<Database.Error> errors)
    {

        log(null, System.now(), null, databaseErrorString(errors) ,null, null, LogType.DATABASE_ERROR.name(), LogSubType.UNDEFINED);

    }

    /**
     * The public method that allows to publish the DML Database error information as an event
     * *
     * @author      jgallaga
     * @date        10/09/2020
     * @description
     *              Obtains the data of the errors into a String to be sent in the message field
     * @param       error - The Database.Error from a DML
     * @param       className - The name of the class from where this method was called
     */
    global static void log(List<Database.Error> errors, String className)
    {
        log(null, System.now(), null, databaseErrorString(errors) ,className, null, LogType.DATABASE_ERROR.name(), LogSubType.UNDEFINED);
    }

    /**
     * The public method that allows to publish the DML Database error information as an event
     * *
     * @author      jgallaga
     * @date        10/09/2020
     * @description
     *              Obtains the data of the errors into a String to be sent in the message field
     * @param       error - The Database.Error from a DML
     * @param       className - The name of the class from where this method was called
     * @param       relatedTo - The Id of the record or process related to this error
     */
    global static void log(List<Database.Error> errors, String className, String relatedTo)
    {
        log(null, System.now(), null, databaseErrorString(errors) ,className, relatedTo, LogType.DATABASE_ERROR.name(), LogSubType.UNDEFINED);
    }

    //#region loggin without exceptions

   /**
     *
     * *
     * @author      jgallaga
     * @date        09/09/2020
     * @description
     *              Just publishes what is available up to this point ven if there is
     *              nothing in the debugger
     */
    global static void log()
    {
        if(debugLogger != null)
        {
            log(null, System.now(), null, null, null, null, LogType.DEBUGDUMP.name(), null);
        }
    }

    /**
     * @author      jgallaga
     * @date        15/09/20
     * @descripion
     *              This log allows sending de debug dump plus a custom message
     * @param       customMessage - A custom text to append to the log entry
     */
    global static void log(String customMessage)
    {
        log(null, System.now(), null, customMessage, null, null, LogType.DEBUGDUMP.name(), null);
    }

    /**
     * @author      jgallaga
     * @date        15/09/20
     * @descripion
     *              This log allows sending de debug dump plus a custom message
     *              and a class name
     * @param       customMessage - A custom text to append to the log entry
     * @param       className - The class from where the log was called
     */
    global static void log(String customMessage, String className)
    {
        log(null, System.now(), null,customMessage, className, null, LogType.DEBUGDUMP.name(), null);
    }

    /**
     * @author      jgallaga
     * @date        15/09/20
     * @descripion
     *              This log allows sending de debug dump plus a custom message
     *              a class name and the record or process involved
     * @param       customMessage - A custom text to append to the log entry
     * @param       className - The class from where the log was called
     * @param       recordID - The Id of the record or process that is related to the log
     */
    global static void log(String customMessage, String className, String recordId)
    {
        log(null, System.now(), null, customMessage, className, recordId, LogType.DEBUGDUMP.name(), null);
    }

    //#endregion

    //#region util methods

    /**
     * @author      jgallaga
     * @date        09/09/2020
     * @description
     *              This method obtains each dml entry and creates a single String that is returned
     * @param       dlmEx - The DML Exception
     * @return      String - The DML data moved to a String
     */
    private static String dmlExceptionString(DmlException dmlEx)
    {
        if(dmLEx != null)
        {
            Integer rowsFailed = dmlEx.getNumDml();
            String[] errors = new String[] {};

            while(rowsFailed-- > 0)
            {
                errors.add(
                    '\r\n\t\tRow ' + rowsFailed
                    + ' exception: ' + dmlEx.getDmlMessage(rowsFailed)
                    + '\r\n\t\tFields: ' + String.join(dmlEx.getDmlFieldNames(rowsFailed), ', ')
                    + '\r\n\t\tId: ' + dmlEx.getDmlId(rowsFailed)
                    );
            }

            return 'NTS1 EXCEPTION:\r\n\tType: DmlException'
              + '\r\n\tMessage: ' + dmlEx.getMessage()
              + '\r\n\tRows failed: ' + dmlEx.getNumDml()
              + String.join(errors, '\r\n\t');
        }

        return '';
    }

    /**
     * @author      jgallaga
     * @date        17/09/2020
     * @description
     *              This method obtains each dml entry and creates a single String that is returned
     * @param       dlmEx - The DML Exception
     * @return      String - The DML data moved to a String
     */
    private static String databaseErrorString(List<Database.Error> errors)
    {
        if(errors != null && !errors.isEmpty())
        {
            Integer errorIndex = errors.size();
            String message = '';

            while(errorIndex-- > 0)
            {
                message += 'Got error ' + errors[errorIndex].getStatusCode()
                           + ': ' + errors[errorIndex].getMessage()
                           + 'on field(s) ' + String.join(errors[errorIndex].getFields(), ',');
            }

            return message;
        }
        return '';
    }

    //#endregion

}