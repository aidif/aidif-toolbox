classdef Constants
    properties (Constant)
        % Inputs
        ERROR_ID_MISSING_COLUMN         = "AIDIF:InvalidInput:MissingColumn"
        ERROR_ID_INVALID_DATA_TYPE      = "AIDIF:InvalidInput:InvalidDataType"
        ERROR_ID_INVALID_VALUE_RANGE    = "AIDIF:InvalidInput:InvalidValueRange"
        ERROR_ID_INSUFFICIENT_DATA      = "AIDIF:InvalidInput:InsufficientData"
        ERROR_ID_UNSORTED_DATA          = "AIDIF:InvalidInput:Unsorted"
        ERROR_ID_DUPLICATE_TIMESTAMPS   = "AIDIF:InvalidInput:DuplicatedValues"
        ERROR_ID_INVALID_PATH_FORMAT    = "AIDIF:InvalidInput:InvalidPathFormat"

        % Business logic
        ERROR_ID_OVERLAPPING_DELIVERIES = "AIDIF:BusinessLogic:OverlappingDeliveries"
        ERROR_ID_INCONSISTENT_STRUCTURE = "AIDIF:BusinessLogic:InconsistentStructure"
        
        % System/Version errors
        ERROR_ID_VERSION_NOT_FOUND      = "AIDIF:Version:VersionNotFound"
    end

end
