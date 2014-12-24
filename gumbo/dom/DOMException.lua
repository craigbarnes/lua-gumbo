local pairs, setmetatable = pairs, setmetatable
local _ENV = nil

local DOMException = {
    INDEX_SIZE_ERR = 1,
    HIERARCHY_REQUEST_ERR = 3,
    WRONG_DOCUMENT_ERR = 4,
    INVALID_CHARACTER_ERR = 5,
    NO_MODIFICATION_ALLOWED_ERR = 7,
    NOT_FOUND_ERR = 8,
    NOT_SUPPORTED_ERR = 9,
    INUSE_ATTRIBUTE_ERR = 10,
    INVALID_STATE_ERR = 11,
    SYNTAX_ERR = 12,
    INVALID_MODIFICATION_ERR = 13,
    NAMESPACE_ERR = 14,
    INVALID_ACCESS_ERR = 15,
    SECURITY_ERR = 18,
    NETWORK_ERR = 19,
    ABORT_ERR = 20,
    URL_MISMATCH_ERR = 21,
    QUOTA_EXCEEDED_ERR = 22,
    TIMEOUT_ERR = 23,
    INVALID_NODE_TYPE_ERR = 24,
    DATA_CLONE_ERR = 25
}

function DOMException:__tostring()
    return ("%s: %s"):format(self.name, self.message)
end

local codes = {
    IndexSizeError = 1,
    HierarchyRequestError = 3,
    WrongDocumentError = 4,
    InvalidCharacterError = 5,
    NoModificationAllowedError = 7,
    NotFoundError = 8,
    NotSupportedError = 9,
    InUseAttributeError = 10,
    InvalidStateError = 11,
    SyntaxError = 12,
    InvalidModificationError = 13,
    NamespaceError = 14,
    InvalidAccessError = 15,
    SecurityError = 18,
    NetworkError = 19,
    AbortError = 20,
    URLMismatchError = 21,
    QuotaExceededError = 22,
    TimeoutError = 23,
    InvalidNodeTypeError = 24,
    DataCloneError = 25
}

local messages = {
    IndexSizeError = "The index is not in the allowed range.",
    HierarchyRequestError = "The operation would yield an incorrect node tree.",
    WrongDocumentError = "The object is in the wrong document.",
    InvalidCharacterError = "The string contains invalid characters.",
    NoModificationAllowedError = "The object can not be modified.",
    NotFoundError = "The object can not be found here.",
    NotSupportedError = "The operation is not supported.",
    InUseAttributeError = "The attribute is in use.",
    InvalidStateError = "The object is in an invalid state.",
    SyntaxError = "The string did not match the expected pattern.",
    InvalidModificationError = "The object can not be modified in this way.",
    NamespaceError = "The operation is not allowed by Namespaces in XML.",
    InvalidAccessError = "The object does not support the operation or argument.",
    SecurityError = "The operation is insecure.",
    NetworkError = "A network error occurred.",
    AbortError = "The operation was aborted.",
    URLMismatchError = "The given URL does not match another URL.",
    QuotaExceededError = "The quota has been exceeded.",
    TimeoutError = "The operation timed out.",
    InvalidNodeTypeError = "The supplied node is incorrect or has an incorrect ancestor for this operation.",
    DataCloneError = "The object can not be cloned.",
    EncodingError = "The encoding operation (either encoded or decoding) failed.",
    NotReadableError = "The I/O read operation failed.",
    UnknownError = "The operation failed for an unknown transient reason (e.g. out of memory).",
    ConstraintError = "A mutation operation in a transaction failed because a constraint was not satisfied.",
    DataError = "Provided data is inadequate.",
    TransactionInactiveError = "A request was placed against a transaction which is currently not active, or which is finished.",
    ReadOnlyError = 'The mutating operation was attempted in a "readonly" transaction.',
    VersionError = "An attempt was made to open a database using a lower version than the existing version.",
    OperationError = "The operation failed for an operation-specific reason."
}

local objects = {}
for name, message in pairs(messages) do
    local code = codes[name]
    local t = {
        name = name,
        message = message,
        code = code
    }
    objects[name] = setmetatable(t, DOMException)
    if code then
        objects[code] = t
    end
end

local function constructor(self, nameOrCode)
    return objects[nameOrCode] or objects.UnknownError
end

return setmetatable(DOMException, {__call = constructor})
