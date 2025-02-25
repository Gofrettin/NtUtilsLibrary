unit Ntapi.ntioapi.fsctl;

{
  The file provides definitions for accessing volume information and issuing
  FSCTL requests to the file system.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, DelphiApi.Reflection;

const
  // WDK::ntifs.h - fs control flags
  FILE_VC_QUOTA_NONE = $00000000;
  FILE_VC_QUOTA_TRACK = $00000001;
  FILE_VC_QUOTA_ENFORCE = $00000002;
  FILE_VC_CONTENT_INDEX_DISABLED = $00000008;
  FILE_VC_LOG_QUOTA_THRESHOLD = $00000010;
  FILE_VC_LOG_QUOTA_LIMIT = $00000020;
  FILE_VC_LOG_VOLUME_THRESHOLD = $00000040;
  FILE_VC_LOG_VOLUME_LIMIT = $00000080;
  FILE_VC_QUOTAS_INCOMPLETE = $00000100;
  FILE_VC_QUOTAS_REBUILDING = $00000200;

  // WDK::ntifs.h - opportunistic lock flags (FSCTL 144)
  OPLOCK_LEVEL_CACHE_READ = $00000001;
  OPLOCK_LEVEL_CACHE_HANDLE = $00000002;
  OPLOCK_LEVEL_CACHE_WRITE = $00000004;

  // WDK::ntifs.h - opportunistic lock request input flags (FSCTL 144)
  REQUEST_OPLOCK_INPUT_FLAG_REQUEST = $00000001;
  REQUEST_OPLOCK_INPUT_FLAG_ACK = $00000002;
  REQUEST_OPLOCK_INPUT_FLAG_COMPLETE_ACK_ON_CLOSE = $00000004;

  // WDK::ntifs.h - opportunistic lock request output flags (FSCTL 144)
  REQUEST_OPLOCK_OUTPUT_FLAG_ACK_REQUIRED = $00000001;
  REQUEST_OPLOCK_OUTPUT_FLAG_MODES_PROVIDED = $00000002;

  // WDK::ntifs.h - opportunistic lock version (FSCTL 144)
  REQUEST_OPLOCK_CURRENT_VERSION = 1;

  // WDK::ntifs.h - windows overlay filter version (FSCTL 195 & 196)
  WOF_CURRENT_VERSION = 1;

  // WDK::ntifs.h - WOF file provider version (FSCTL 195 & 196)
  FILE_PROVIDER_CURRENT_VERSION = 1;

type
  { Volume Information }

  // WDK::wdm.h
  [SDKName('FS_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'FileFs'), Range(1)]
  TFsInfoClass = (
    FileFsReserved = 0,
    FileFsVolumeInformation = 1,        // q: TFileFsVolumeInformation
    FileFsLabelInformation = 2,         // s: TFileFsLabelInformation
    FileFsSizeInformation = 3,          // q: TFileFsSizeInformation
    FileFsDeviceInformation = 4,        // q: TFileFsDeviceInformation
    FileFsAttributeInformation = 5,     // q: TFileFsAttributeInformation
    FileFsControlInformation = 6,       // q, s: TFileFsControlInformation
    FileFsFullSizeInformation = 7,      // q: TFileFsFullSizeInformation
    FileFsObjectIdInformation = 8,      // q, s: TFileFsObjectIdInformation
    FileFsDriverPathInformation = 9,    // q: TFileFsDriverPathInformation
    FileFsVolumeFlagsInformation = 10,  // q, s: Cardinal
    FileFsSectorSizeInformation = 11,
    FileFsDataCopyInformation = 12,
    FileFsMetadataSizeInformation = 13,
    FileFsFullSizeInformationEx = 14
  );

  // WDK::ntddk.h - info class 1
  [SDKName('FILE_FS_VOLUME_INFORMATION')]
  TFileFsVolumeInformation = record
    VolumeCreationTime: TLargeInteger;
    VolumeSerialNumber: Cardinal;
    [Counter(ctBytes)] VolumeLabelLength: Cardinal;
    SupportsObjects: Boolean;
    VolumeLabel: TAnysizeArray<WideChar>;
  end;
  PFileFsVolumeInformation = ^TFileFsVolumeInformation;

  // WDK::ntddk.h - info class 2
  [SDKName('FILE_FS_LABEL_INFORMATION')]
  TFileFsLabelInformation = record
    [Counter(ctBytes)] VolumeLabelLength: Cardinal;
    VolumeLabel: TAnysizeArray<WideChar>;
  end;
  PFileFsLabelInformation = ^TFileFsLabelInformation;

  // WDK::ntddk.h - info class 3
  [SDKName('FILE_FS_SIZE_INFORMATION')]
  TFileFsSizeInformation = record
    TotalAllocationUnits: UInt64;
    AvailableAllocationUnits: UInt64;
    SectorsPerAllocationUnit: Cardinal;
    [Bytes] BytesPerSector: Cardinal;
  end;
  PFileFsSizeInformation = ^TFileFsSizeInformation;

  // WDK::ntifs.h
  {$SCOPEDENUMS ON}
  [SDKName('DEVICE_TYPE')]
  [NamingStyle(nsSnakeCase, 'FILE_DEVICE')]
  TDeviceType = (
    FILE_DEVICE_BEEP = $00000001,
    FILE_DEVICE_CD_ROM = $00000002,
    FILE_DEVICE_CD_ROM_FILE_SYSTEM = $00000003,
    FILE_DEVICE_CONTROLLER = $00000004,
    FILE_DEVICE_DATALINK = $00000005,
    FILE_DEVICE_DFS = $00000006,
    FILE_DEVICE_DISK = $00000007,
    FILE_DEVICE_DISK_FILE_SYSTEM = $00000008,
    FILE_DEVICE_FILE_SYSTEM = $00000009,
    FILE_DEVICE_INPORT_PORT = $0000000a,
    FILE_DEVICE_KEYBOARD = $0000000b,
    FILE_DEVICE_MAILSLOT = $0000000c,
    FILE_DEVICE_MIDI_IN = $0000000d,
    FILE_DEVICE_MIDI_OUT = $0000000e,
    FILE_DEVICE_MOUSE = $0000000f,
    FILE_DEVICE_MULTI_UNC_PROVIDER = $00000010,
    FILE_DEVICE_NAMED_PIPE = $00000011,
    FILE_DEVICE_NETWORK = $00000012,
    FILE_DEVICE_NETWORK_BROWSER = $00000013,
    FILE_DEVICE_NETWORK_FILE_SYSTEM = $00000014,
    FILE_DEVICE_NULL = $00000015,
    FILE_DEVICE_PARALLEL_PORT = $00000016,
    FILE_DEVICE_PHYSICAL_NETCARD = $00000017,
    FILE_DEVICE_PRINTER = $00000018,
    FILE_DEVICE_SCANNER = $00000019,
    FILE_DEVICE_SERIAL_MOUSE_PORT = $0000001a,
    FILE_DEVICE_SERIAL_PORT = $0000001b,
    FILE_DEVICE_SCREEN = $0000001c,
    FILE_DEVICE_SOUND = $0000001d,
    FILE_DEVICE_STREAMS = $0000001e,
    FILE_DEVICE_TAPE = $0000001f,
    FILE_DEVICE_TAPE_FILE_SYSTEM = $00000020,
    FILE_DEVICE_TRANSPORT = $00000021,
    FILE_DEVICE_UNKNOWN = $00000022,
    FILE_DEVICE_VIDEO = $00000023,
    FILE_DEVICE_VIRTUAL_DISK = $00000024,
    FILE_DEVICE_WAVE_IN = $00000025,
    FILE_DEVICE_WAVE_OUT = $00000026,
    FILE_DEVICE_8042_PORT = $00000027,
    FILE_DEVICE_NETWORK_REDIRECTOR = $00000028,
    FILE_DEVICE_BATTERY = $00000029,
    FILE_DEVICE_BUS_EXTENDER = $0000002a,
    FILE_DEVICE_MODEM = $0000002b,
    FILE_DEVICE_VDM = $0000002c,
    FILE_DEVICE_MASS_STORAGE = $0000002d,
    FILE_DEVICE_SMB = $0000002e,
    FILE_DEVICE_KS = $0000002f,
    FILE_DEVICE_CHANGER = $00000030,
    FILE_DEVICE_SMARTCARD = $00000031,
    FILE_DEVICE_ACPI = $00000032,
    FILE_DEVICE_DVD = $00000033,
    FILE_DEVICE_FULLSCREEN_VIDEO = $00000034,
    FILE_DEVICE_DFS_FILE_SYSTEM = $00000035,
    FILE_DEVICE_DFS_VOLUME = $00000036,
    FILE_DEVICE_SERENUM = $00000037,
    FILE_DEVICE_TERMSRV = $00000038,
    FILE_DEVICE_KSEC = $00000039,
    FILE_DEVICE_FIPS = $0000003a,
    FILE_DEVICE_INFINIBAND = $0000003b,
    FILE_DEVICE_TYPE_60 = $0000003c,
    FILE_DEVICE_TYPE_61 = $0000003d,
    FILE_DEVICE_VMBUS = $0000003e,
    FILE_DEVICE_CRYPT_PROVIDER = $0000003f,
    FILE_DEVICE_WPD = $00000040,
    FILE_DEVICE_BLUETOOTH = $00000041,
    FILE_DEVICE_MT_COMPOSITE = $00000042,
    FILE_DEVICE_MT_TRANSPORT = $00000043,
    FILE_DEVICE_BIOMETRIC = $00000044,
    FILE_DEVICE_PMI = $00000045,
    FILE_DEVICE_EHSTOR = $00000046,
    FILE_DEVICE_DEVAPI = $00000047,
    FILE_DEVICE_GPIO = $00000048,
    FILE_DEVICE_USBEX = $00000049,
    FILE_DEVICE_CONSOLE = $00000050,
    FILE_DEVICE_NFP = $00000051,
    FILE_DEVICE_SYSENV = $00000052,
    FILE_DEVICE_VIRTUAL_BLOCK = $00000053,
    FILE_DEVICE_POINT_OF_SERVICE = $00000054,
    FILE_DEVICE_STORAGE_REPLICATION = $00000055,
    FILE_DEVICE_TRUST_ENV = $00000056,
    FILE_DEVICE_UCM = $00000057,
    FILE_DEVICE_UCMTCPCI = $00000058,
    FILE_DEVICE_PERSISTENT_MEMORY = $00000059,
    FILE_DEVICE_NVDIMM = $0000005a,
    FILE_DEVICE_HOLOGRAPHIC = $0000005b,
    FILE_DEVICE_SDFXHCI = $0000005c,
    FILE_DEVICE_UCMUCSI = $0000005d
  );
  {$SCOPEDENUMS OFF}

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'METHOD')]
  TIoControlMethod = (
    METHOD_BUFFERED = 0,
    METHOD_IN_DIRECT = 1,
    METHOD_OUT_DIRECT = 2,
    METHOD_NEITHER = 3
  );

  [FlagName(FILE_REMOVABLE_MEDIA, 'Removable Media')]
  [FlagName(FILE_READ_ONLY_DEVICE, 'Read-only Device')]
  [FlagName(FILE_FLOPPY_DISKETTE, 'Floppy Disk')]
  [FlagName(FILE_WRITE_ONCE_MEDIA, 'Write-once Media')]
  [FlagName(FILE_REMOTE_DEVICE, 'Remote Device')]
  [FlagName(FILE_DEVICE_IS_MOUNTED, 'Device Is Mounted')]
  [FlagName(FILE_VIRTUAL_VOLUME, 'Virtual Volume')]
  [FlagName(FILE_AUTOGENERATED_DEVICE_NAME, 'Autogenerated Device Name')]
  [FlagName(FILE_DEVICE_SECURE_OPEN, 'Device Secure Open')]
  [FlagName(FILE_CHARACTERISTIC_PNP_DEVICE, 'PnP Device')]
  [FlagName(FILE_CHARACTERISTIC_TS_DEVICE, 'TS Device')]
  [FlagName(FILE_CHARACTERISTIC_WEBDAV_DEVICE, 'WebDav Device')]
  [FlagName(FILE_CHARACTERISTIC_CSV, 'CSV')]
  [FlagName(FILE_DEVICE_ALLOW_APPCONTAINER_TRAVERSAL, 'Allow AppContainer Traversal')]
  [FlagName(FILE_PORTABLE_DEVICE, 'Portbale Device')]
  TDeviceCharacteristics = type Cardinal;

  // WDK::wdm.h - info class 4
  [SDKName('FILE_FS_DEVICE_INFORMATION')]
  TFileFsDeviceInformation = record
    DeviceType: TDeviceType;
    Characteristics: TDeviceCharacteristics;
  end;
  PFileFsDeviceInformation = ^TFileFsDeviceInformation;

  [FlagName(FILE_CASE_SENSITIVE_SEARCH, 'Case-sensitive Search')]
  [FlagName(FILE_CASE_PRESERVED_NAMES, 'Case-preserved Names')]
  [FlagName(FILE_UNICODE_ON_DISK, 'Unicode On Disk')]
  [FlagName(FILE_PERSISTENT_ACLS, 'Persistent ACLs')]
  [FlagName(FILE_FILE_COMPRESSION, 'Supports Compression')]
  [FlagName(FILE_VOLUME_QUOTAS, 'Volume Quotas')]
  [FlagName(FILE_SUPPORTS_SPARSE_FILES, 'Supports Sparse Files')]
  [FlagName(FILE_SUPPORTS_REPARSE_POINTS, 'Supports Reparse Points')]
  [FlagName(FILE_SUPPORTS_REMOTE_STORAGE, 'Supports Remote Storage')]
  [FlagName(FILE_RETURNS_CLEANUP_RESULT_INFO, 'Returns Cleanup Result Info')]
  [FlagName(FILE_SUPPORTS_POSIX_UNLINK_RENAME, 'Supports Posix Unlink Rename')]
  [FlagName(FILE_VOLUME_IS_COMPRESSED, 'Volume Is Compressed')]
  [FlagName(FILE_SUPPORTS_OBJECT_IDS, 'Supports Object IDs')]
  [FlagName(FILE_SUPPORTS_ENCRYPTION, 'Supports Encryption')]
  [FlagName(FILE_NAMED_STREAMS, 'Named Streams')]
  [FlagName(FILE_READ_ONLY_VOLUME, 'Read-only Volume')]
  [FlagName(FILE_SEQUENTIAL_WRITE_ONCE, 'Sequential Write Once')]
  [FlagName(FILE_SUPPORTS_TRANSACTIONS, 'Supports Transactions')]
  [FlagName(FILE_SUPPORTS_HARD_LINKS, 'Supports Hardlinks')]
  [FlagName(FILE_SUPPORTS_EXTENDED_ATTRIBUTES, 'Supports EA')]
  [FlagName(FILE_SUPPORTS_OPEN_BY_FILE_ID, 'Supports Open By ID')]
  [FlagName(FILE_SUPPORTS_USN_JOURNAL, 'Supports USN Journal')]
  [FlagName(FILE_SUPPORTS_INTEGRITY_STREAMS, 'Supports Integrity Streams')]
  [FlagName(FILE_SUPPORTS_BLOCK_REFCOUNTING, 'Supports Block Ref. Counting')]
  [FlagName(FILE_SUPPORTS_SPARSE_VDL, 'Supports Sparse VDL')]
  [FlagName(FILE_DAX_VOLUME, 'DAX Volume')]
  [FlagName(FILE_SUPPORTS_GHOSTING, 'Supports Ghosting')]
  TFileSystemAttributes = type Cardinal;

  // WDK::ntifs.h - info class 5
  [SDKName('FILE_FS_ATTRIBUTE_INFORMATION')]
  TFileFsAttributeInformation = record
    FileSystemAttributes: TFileSystemAttributes;
    MaximumComponentNameLength: Integer;
    [Counter(ctBytes)] FileSystemNameLength: Cardinal;
    FileSystemName: TAnysizeArray<WideChar>;
  end;
  PFileFsAttributeInformation = ^TFileFsAttributeInformation;

  [FlagName(FILE_VC_QUOTA_NONE, 'No Quota')]
  [FlagName(FILE_VC_QUOTA_TRACK, 'Track Quota')]
  [FlagName(FILE_VC_QUOTA_ENFORCE, 'Enforce Quota')]
  [FlagName(FILE_VC_CONTENT_INDEX_DISABLED, 'Content Index Disabled')]
  [FlagName(FILE_VC_LOG_QUOTA_THRESHOLD, 'Quota Threshold')]
  [FlagName(FILE_VC_LOG_QUOTA_LIMIT, 'Log Quota Limit')]
  [FlagName(FILE_VC_LOG_VOLUME_THRESHOLD, 'Log Volume Threshold')]
  [FlagName(FILE_VC_LOG_VOLUME_LIMIT, 'Log Volume Limit')]
  [FlagName(FILE_VC_QUOTAS_INCOMPLETE, 'Quotas Incomplete')]
  [FlagName(FILE_VC_QUOTAS_REBUILDING, 'Quotas Rebuilding')]
  TFsControlFlags = type Cardinal;

  // WDK::ntifs.h - info class 6
  [SDKName('FILE_FS_CONTROL_INFORMATION')]
  TFileFsControlInformation = record
    FreeSpaceStartFiltering: UInt64;
    FreeSpaceThreshold: UInt64;
    FreeSpaceStopFiltering: UInt64;
    DefaultQuotaThreshold: UInt64;
    DefaultQuotaLimit: UInt64;
    FileSystemControlFlags: TFsControlFlags;
  end;
  PFileFsControlInformation = ^TFileFsControlInformation;

  // WDK::ntddk.h - info class 7
  [SDKName('FILE_FS_FULL_SIZE_INFORMATION')]
  TFileFsFullSizeInformation = record
    TotalAllocationUnits: UInt64;
    CallerAvailableAllocationUnits: UInt64;
    ActualAvailableAllocationUnits: UInt64;
    SectorsPerAllocationUnit: Cardinal;
    [Bytes] BytesPerSector: Cardinal;
  end;
  PFileFsFullSizeInformation = ^TFileFsFullSizeInformation;

  // WDK::ntddk.h - info class 8
  [SDKName('FILE_FS_OBJECTID_INFORMATION')]
  TFileFsObjectIdInformation = record
    ObjectID: TGuid;
    ExtendedInfo: array [0..2] of TGuid;
  end;
  PFileFsObjectIdInformation = ^TFileFsObjectIdInformation;

  // WDK::ntifs.h - info class 9
  [SDKName('FILE_FS_DRIVER_PATH_INFORMATION')]
  TFileFsDriverPathInformation = record
    DriverInPath: Boolean;
    [Counter(ctBytes)] DriverNameLength: Cardinal;
    DriverName: TAnysizeArray<WideChar>;
  end;
  PFileFsDriverPathInformation = ^TFileFsDriverPathInformation;

  { FSCTLs }

  // WDK::ntifs.h - function numbers for corresponding FSCTL_* codes
  {$SCOPEDENUMS ON}
  TFsCtlFunction = (
    FSCTL_REQUEST_OPLOCK_LEVEL_1 = 0,    // nothing
    FSCTL_REQUEST_OPLOCK_LEVEL_2 = 1,    // nothing
    FSCTL_REQUEST_BATCH_OPLOCK = 2,      // nothing
    FSCTL_OPLOCK_BREAK_ACKNOWLEDGE = 3,  // nothing
    FSCTL_OPBATCH_ACK_CLOSE_PENDING = 4, // nothing
    FSCTL_OPLOCK_BREAK_NOTIFY = 5,       // nothing
    FSCTL_LOCK_VOLUME = 6,               // nothing
    FSCTL_UNLOCK_VOLUME = 7,
    FSCTL_DISMOUNT_VOLUME = 8,
    FSCTL_9,
    FSCTL_IS_VOLUME_MOUNTED = 10,        // nothing
    FSCTL_IS_PATHNAME_VALID = 11,        // in: TPathNameBuffer
    FSCTL_MARK_VOLUME_DIRTY = 12,
    FSCTL_13,
    FSCTL_QUERY_RETRIEVAL_POINTERS = 14,
    FSCTL_GET_COMPRESSION = 15,
    FSCTL_SET_COMPRESSION = 16,
    FSCTL_17,
    FSCTL_18,
    FSCTL_MARK_AS_SYSTEM_HIVE = 19,
    FSCTL_OPLOCK_BREAK_ACK_NO_2 = 20,
    FSCTL_INVALIDATE_VOLUMES = 21,
    FSCTL_QUERY_FAT_BPB = 22,
    FSCTL_REQUEST_FILTER_OPLOCK = 23,     // nothing
    FSCTL_FILESYSTEM_GET_STATISTICS = 24,
    FSCTL_GET_NTFS_VOLUME_DATA = 25,
    FSCTL_GET_NTFS_FILE_RECORD = 26,
    FSCTL_GET_VOLUME_BITMAP = 27,
    FSCTL_GET_RETRIEVAL_POINTERS = 28,
    FSCTL_MOVE_FILE = 29,
    FSCTL_IS_VOLUME_DIRTY = 30,
    FSCTL_31,
    FSCTL_ALLOW_EXTENDED_DASD_IO = 32,
    FSCTL_33,
    FSCTL_34,
    FSCTL_FIND_FILES_BY_SID = 35,
    FSCTL_36,
    FSCTL_37,
    FSCTL_SET_OBJECT_ID = 38,
    FSCTL_GET_OBJECT_ID = 39,
    FSCTL_DELETE_OBJECT_ID = 40,
    FSCTL_SET_REPARSE_POINT = 41,
    FSCTL_GET_REPARSE_POINT = 42,
    FSCTL_DELETE_REPARSE_POINT = 43,
    FSCTL_ENUM_USN_DATA = 44,
    FSCTL_SECURITY_ID_CHECK = 45,
    FSCTL_READ_USN_JOURNAL = 46,
    FSCTL_SET_OBJECT_ID_EXTENDED = 47,
    FSCTL_CREATE_OR_GET_OBJECT_ID = 48,
    FSCTL_SET_SPARSE = 49,
    FSCTL_SET_ZERO_DATA = 50,
    FSCTL_QUERY_ALLOCATED_RANGES = 51,
    FSCTL_ENABLE_UPGRADE = 52,
    FSCTL_SET_ENCRYPTION = 53,
    FSCTL_ENCRYPTION_FSCTL_IO = 54,
    FSCTL_WRITE_RAW_ENCRYPTED = 55,
    FSCTL_READ_RAW_ENCRYPTED = 56,
    FSCTL_CREATE_USN_JOURNAL = 57,
    FSCTL_READ_FILE_USN_DATA = 58,
    FSCTL_WRITE_USN_CLOSE_RECORD = 59,
    FSCTL_EXTEND_VOLUME = 60,
    FSCTL_QUERY_USN_JOURNAL = 61,
    FSCTL_DELETE_USN_JOURNAL = 62,
    FSCTL_MARK_HANDLE = 63,
    FSCTL_SIS_COPYFILE = 64,
    FSCTL_SIS_LINK_FILES = 65,
    FSCTL_66,
    FSCTL_67,
    FSCTL_68,
    FSCTL_RECALL_FILE = 69,
    FSCTL_70,
    FSCTL_READ_FROM_PLEX = 71,
    FSCTL_FILE_PREFETCH = 72,
    FSCTL_73,
    FSCTL_74,
    FSCTL_75,
    FSCTL_MAKE_MEDIA_COMPATIBLE = 76,
    FSCTL_SET_DEFECT_MANAGEMENT = 77,
    FSCTL_QUERY_SPARING_INFO = 78,
    FSCTL_QUERY_ON_DISK_VOLUME_INFO = 79,
    FSCTL_SET_VOLUME_COMPRESSION_STATE = 80,
    FSCTL_TXFS_MODIFY_RM = 81,
    FSCTL_TXFS_QUERY_RM_INFORMATION = 82,
    FSCTL_83,
    FSCTL_TXFS_ROLLFORWARD_REDO = 84,
    FSCTL_TXFS_ROLLFORWARD_UNDO = 85,
    FSCTL_TXFS_START_RM = 86,
    FSCTL_TXFS_SHUTDOWN_RM = 87,
    FSCTL_TXFS_READ_BACKUP_INFORMATION = 88,
    FSCTL_TXFS_WRITE_BACKUP_INFORMATION = 89,
    FSCTL_TXFS_CREATE_SECONDARY_RM = 90,
    FSCTL_TXFS_GET_METADATA_INFO = 91,
    FSCTL_TXFS_GET_TRANSACTED_VERSION = 92,
    FSCTL_93,
    FSCTL_TXFS_SAVEPOINT_INFORMATION = 94,
    FSCTL_TXFS_CREATE_MINIVERSION = 95,
    FSCTL_96,
    FSCTL_97,
    FSCTL_98,
    FSCTL_TXFS_TRANSACTION_ACTIVE = 99,
    FSCTL_100,
    FSCTL_SET_ZERO_ON_DEALLOCATION = 101, // nothing
    FSCTL_SET_REPAIR = 102,
    FSCTL_GET_REPAIR = 103,
    FSCTL_WAIT_FOR_REPAIR = 104,
    FSCTL_105,
    FSCTL_INITIATE_REPAIR = 106,
    FSCTL_CSC_INTERNAL = 107,
    FSCTL_SHRINK_VOLUME = 108,
    FSCTL_SET_SHORT_NAME_BEHAVIOR = 109,
    FSCTL_DFSR_SET_GHOST_HANDLE_STATE = 110,
    FSCTL_111,
    FSCTL_112,
    FSCTL_113,
    FSCTL_114,
    FSCTL_115,
    FSCTL_116,
    FSCTL_117,
    FSCTL_118,
    FSCTL_119,
    FSCTL_TXFS_LIST_TRANSACTION_LOCKED_FILES = 120,
    FSCTL_TXFS_LIST_TRANSACTIONS = 121,
    FSCTL_QUERY_PAGEFILE_ENCRYPTION = 122,
    FSCTL_RESET_VOLUME_ALLOCATION_HINTS = 123,
    FSCTL_QUERY_DEPENDENT_VOLUME = 124,
    FSCTL_SD_GLOBAL_CHANGE = 125, // in: TSdGlobalChangeInput, out: TSdGlobalChangeOutput
    FSCTL_TXFS_READ_BACKUP_INFORMATION2 = 126,
    FSCTL_LOOKUP_STREAM_FROM_CLUSTER = 127,
    FSCTL_TXFS_WRITE_BACKUP_INFORMATION2 = 128,
    FSCTL_FILE_TYPE_NOTIFICATION = 129,
    FSCTL_FILE_LEVEL_TRIM = 130,
    FSCTL_131,
    FSCTL_132,
    FSCTL_133,
    FSCTL_134,
    FSCTL_135,
    FSCTL_136,
    FSCTL_137,
    FSCTL_138,
    FSCTL_139,
    FSCTL_GET_BOOT_AREA_INFO = 140,
    FSCTL_GET_RETRIEVAL_POINTER_BASE = 141,
    FSCTL_SET_PERSISTENT_VOLUME_STATE = 142,
    FSCTL_QUERY_PERSISTENT_VOLUME_STATE = 143,
    FSCTL_REQUEST_OPLOCK = 144,                // in: TRequestOplockInputBuffer, out: TRequestOplockOutputBuffer
    FSCTL_CSV_TUNNEL_REQUEST = 145,
    FSCTL_IS_CSV_FILE = 146,
    FSCTL_QUERY_FILE_SYSTEM_RECOGNITION = 147,
    FSCTL_CSV_GET_VOLUME_PATH_NAME = 148,
    FSCTL_CSV_GET_VOLUME_NAME_FOR_VOLUME_MOUNT_POINT = 149,
    FSCTL_CSV_GET_VOLUME_PATH_NAMES_FOR_VOLUME_NAME = 150,
    FSCTL_IS_FILE_ON_CSV_VOLUME = 151,
    FSCTL_CORRUPTION_HANDLING = 152,
    FSCTL_OFFLOAD_READ = 153,
    FSCTL_OFFLOAD_WRITE = 154,
    FSCTL_CSV_INTERNAL = 155,
    FSCTL_SET_PURGE_FAILURE_MODE = 156,
    FSCTL_QUERY_FILE_LAYOUT = 157,
    FSCTL_IS_VOLUME_OWNED_BYCSVFS = 158,
    FSCTL_GET_INTEGRITY_INFORMATION = 159,
    FSCTL_SET_INTEGRITY_INFORMATION = 160,
    FSCTL_QUERY_FILE_REGIONS = 161,
    FSCTL_162,
    FSCTL_163,
    FSCTL_164,
    FSCTL_165,
    FSCTL_166,
    FSCTL_167,
    FSCTL_168,
    FSCTL_169,
    FSCTL_170,
    FSCTL_RKF_INTERNAL = 171,
    FSCTL_SCRUB_DATA = 172,
    FSCTL_REPAIR_COPIES = 173,
    FSCTL_DISABLE_LOCAL_BUFFERING = 174,
    FSCTL_CSV_MGMT_LOCK = 175,
    FSCTL_CSV_QUERY_DOWN_LEVEL_FILE_SYSTEM_CHARACTERISTICS = 176,
    FSCTL_ADVANCE_FILE_ID = 177,
    FSCTL_CSV_SYNC_TUNNEL_REQUEST = 178,
    FSCTL_CSV_QUERY_VETO_FILE_DIRECT_IO = 179,
    FSCTL_WRITE_USN_REASON = 180,
    FSCTL_CSV_CONTROL = 181,
    FSCTL_GET_REFS_VOLUME_DATA = 182,
    FSCTL_183,
    FSCTL_184,
    FSCTL_CSV_H_BREAKING_SYNC_TUNNEL_REQUEST = 185,
    FSCTL_186,
    FSCTL_QUERY_STORAGE_CLASSES = 187,
    FSCTL_QUERY_REGION_INFO = 188,
    FSCTL_USN_TRACK_MODIFIED_RANGES = 189,
    FSCTL_190,
    FSCTL_191,
    FSCTL_QUERY_SHARED_VIRTUAL_DISK_SUPPORT = 192,
    FSCTL_SVHDX_SYNC_TUNNEL_REQUEST = 193,
    FSCTL_SVHDX_SET_INITIATOR_INFORMATION = 194,
    FSCTL_SET_EXTERNAL_BACKING = 195, // in: TFileProviderExternalInfoV1
    FSCTL_GET_EXTERNAL_BACKING = 196, // out: TFileProviderExternalInfoV1
    FSCTL_DELETE_EXTERNAL_BACKING = 197,
    FSCTL_ENUM_EXTERNAL_BACKING = 198,
    FSCTL_ENUM_OVERLAY = 199,
    FSCTL_200,
    FSCTL_201,
    FSCTL_202,
    FSCTL_203,
    FSCTL_ADD_OVERLAY = 204,
    FSCTL_REMOVE_OVERLAY = 205,
    FSCTL_UPDATE_OVERLAY = 206,
    FSCTL_207,
    FSCTL_SHUFFLE_FILE = 208,
    FSCTL_DUPLICATE_EXTENTS_TO_FILE = 209,
    FSCTL_210,
    FSCTL_SPARSE_OVERALLOCATE = 211,
    FSCTL_STORAGE_QOS_CONTROL = 212,
    FSCTL_213,
    FSCTL_214,
    FSCTL_INITIATE_FILE_METADATA_OPTIMIZATION = 215,
    FSCTL_QUERY_FILE_METADATA_OPTIMIZATION = 216,
    FSCTL_SVHDX_ASYNC_TUNNEL_REQUEST = 217,
    FSCTL_GET_WOF_VERSION = 218,
    FSCTL_HCS_SYNC_TUNNEL_REQUEST = 219,
    FSCTL_HCS_ASYNC_TUNNEL_REQUEST = 220,
    FSCTL_QUERY_EXTENT_READ_CACHE_INFO = 221,
    FSCTL_QUERY_REFS_VOLUME_COUNTER_INFO = 222,
    FSCTL_CLEAN_VOLUME_METADATA = 223,
    FSCTL_SET_INTEGRITY_INFORMATION_EX = 224,
    FSCTL_SUSPEND_OVERLAY = 225,
    FSCTL_VIRTUAL_STORAGE_QUERY_PROPERTY = 226,
    FSCTL_FILESYSTEM_GET_STATISTICS_EX = 227,
    FSCTL_QUERY_VOLUME_CONTAINER_STATE = 228,
    FSCTL_SET_LAYER_ROOT = 229,
    FSCTL_QUERY_DIRECT_ACCESS_EXTENTS = 230,
    FSCTL_NOTIFY_STORAGE_SPACE_ALLOCATION = 231,
    FSCTL_SSDI_STORAGE_REQUEST = 232,
    FSCTL_QUERY_DIRECT_IMAGE_ORIGINAL_BASE = 233,
    FSCTL_READ_UNPRIVILEGED_USN_JOURNAL = 234,
    FSCTL_GHOST_FILE_EXTENTS = 235,
    FSCTL_QUERY_GHOSTED_FILE_EXTENTS = 236,
    FSCTL_UNMAP_SPACE = 237,
    FSCTL_HCS_SYNC_NO_WRITE_TUNNEL_REQUEST = 238,
    FSCTL_239,
    FSCTL_START_VIRTUALIZATION_INSTANCE = 240,
    FSCTL_GET_FILTER_FILE_IDENTIFIER = 241,
    FSCTL_STREAMS_ASSOCIATE_ID = 242,
    FSCTL_STREAMS_QUERY_ID = 243,
    FSCTL_GET_RETRIEVAL_POINTERS_AND_REFCOUNT = 244,
    FSCTL_QUERY_VOLUME_NUMA_INFO = 245,
    FSCTL_REFS_DEALLOCATE_RANGES = 246,
    FSCTL_QUERY_REFS_SMR_VOLUME_INFO = 247,
    FSCTL_SET_REFS_SMR_VOLUME_GC_PARAMETERS = 248,
    FSCTL_SET_REFS_FILE_STRICTLY_SEQUENTIAL = 249,
    FSCTL_DUPLICATE_EXTENTS_TO_FILE_EX = 250,
    FSCTL_QUERY_BAD_RANGES = 251,
    FSCTL_SET_DAX_ALLOC_ALIGNMENT_HINT = 252,
    FSCTL_DELETE_CORRUPTED_REFS_CONTAINER = 253,
    FSCTL_SCRUB_UNDISCOVERABLE_ID = 254,
    FSCTL_NOTIFY_DATA_CHANGE = 255,
    FSCTL_START_VIRTUALIZATION_INSTANCE_EX = 256,
    FSCTL_ENCRYPTION_KEY_CONTROL = 257,
    FSCTL_VIRTUAL_STORAGE_SET_BEHAVIOR = 258,
    FSCTL_SET_REPARSE_POINT_EX = 259,
    FSCTL_260,
    FSCTL_261,
    FSCTL_262,
    FSCTL_263,
    FSCTL_REARRANGE_FILE = 264,
    FSCTL_VIRTUAL_STORAGE_PASSTHROUGH = 265,
    FSCTL_GET_RETRIEVAL_POINTER_COUNT = 266,
    FSCTL_ENABLE_PER_IO_FLAGS = 267
  );
  {$SCOPEDENUMS OFF}

  // WDK::ntifs.h - FSCTL 11 (input)
  [SDKName('PATHNAME_BUFFER')]
  TPathNameBuffer = record
    PathNameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;

  // WDK::ntifs.h
  TSdGlobalChangeType = (
    SD_GLOBAL_CHANGE_TYPE_MACHINE_SID = $00000001,
    SD_GLOBAL_CHANGE_TYPE_QUERY_STATS = $00010000,
    SD_GLOBAL_CHANGE_TYPE_ENUM_SDS = $00020000
  );

  // WDK::ntifs.h
  [SDKName('SD_CHANGE_MACHINE_SID_INPUT')]
  TSdChangeMachineSidInput = record
    [Hex] CurrentMachineSIDOffset: Word;
    [Bytes] CurrentMachineSIDLength: Word;
    [Hex] NewMachineSIDOffset: Word;
    [Bytes] NewMachineSIDLength: Word;
  end;
  PSdChangeMachineSidInput = ^TSdChangeMachineSidInput;

  // WDK::ntifs.h
  [SDKName('SD_CHANGE_MACHINE_SID_OUTPUT')]
  TSdChangeMachineSidOutput = record
    NumSDChangedSuccess: UInt64;
    NumSDChangedFail: UInt64;
    NumSDUnused: UInt64;
    NumSDTotal: UInt64;
    NumMftSDChangedSuccess: UInt64;
    NumMftSDChangedFail: UInt64;
    NumMftSDTotal: UInt64;
  end;

  // WDK::ntifs.h
  [SDKName('SD_QUERY_STATS_OUTPUT')]
  TSdQueryStatsOutput = record
    [Bytes] SdsStreamSize: UInt64;
    [Bytes] SdsAllocationSize: UInt64;
    [Bytes] SiiStreamSize: UInt64;
    [Bytes] SiiAllocationSize: UInt64;
    [Bytes] SdhStreamSize: UInt64;
    [Bytes] SdhAllocationSize: UInt64;
    NumSDTotal: UInt64;
    NumSDUnused: UInt64;
  end;

  // WDK::ntifs.h
  [SDKName('SD_ENUM_SDS_INPUT')]
  TSdEnumSDsInput = record
    [Hex] StartingOffset: UInt64;
    MaxSDEntriesToReturn: UInt64;
  end;

  // WDK::ntifs.h
  [SDKName('SD_ENUM_SDS_ENTRY')]
  TSdEnumSDsEntry = record
    [Hex] Hash: Cardinal;
    SecurityId: Cardinal;
    Offset: UInt64;
    [Bytes] Length: Cardinal;
    Descriptor: TAnysizeArray<Byte>;
  end;

  // WDK::ntifs.h
  [SDKName('SD_ENUM_SDS_OUTPUT')]
  TSdEnumSDsOutput = record
    NextOffset: UInt64;
    NumSDEntriesReturned: UInt64;
    [Bytes] NumSDBytesReturned: UInt64;
    SDEntry: TSdEnumSDsEntry;
  end;

  // WDK::ntifs.h - function 125 (input)
  [SDKName('SD_GLOBAL_CHANGE_INPUT')]
  TSdGlobalChangeInput = record
    [Reserved] Flags: Cardinal;
  case ChangeType: TSdGlobalChangeType of
    SD_GLOBAL_CHANGE_TYPE_MACHINE_SID: (
      SdChange: TSdChangeMachineSidInput;
    );

    SD_GLOBAL_CHANGE_TYPE_QUERY_STATS: (
      Reserved: Cardinal;
    );

    SD_GLOBAL_CHANGE_TYPE_ENUM_SDS: (
      SdEnumSds: TSdEnumSDsInput;
    );
  end;
  PSdGlobalChangeInput = ^TSdGlobalChangeInput;

  // WDK::ntifs.h - function 125 (output)
  [SDKName('SD_GLOBAL_CHANGE_OUTPUT')]
  TSdGlobalChangeOutput = record
    [Reserved] Flags: Cardinal;
  case ChangeType: TSdGlobalChangeType of
    SD_GLOBAL_CHANGE_TYPE_MACHINE_SID: (
      SdChange: TSdChangeMachineSidOutput;
    );

    SD_GLOBAL_CHANGE_TYPE_QUERY_STATS: (
      SdQueryStats: TSdQueryStatsOutput;
    );

    SD_GLOBAL_CHANGE_TYPE_ENUM_SDS: (
      SdEnumSds: TSdEnumSDsOutput;
    );
  end;
  PSdGlobalChangeOutput = ^TSdGlobalChangeOutput;

  [FlagName(OPLOCK_LEVEL_CACHE_READ, 'Cache Read')]
  [FlagName(OPLOCK_LEVEL_CACHE_HANDLE, 'Cache Handle')]
  [FlagName(OPLOCK_LEVEL_CACHE_WRITE, 'Cache Write')]
  TOpLockLevel = type Cardinal;

  [FlagName(REQUEST_OPLOCK_INPUT_FLAG_REQUEST, 'Request')]
  [FlagName(REQUEST_OPLOCK_INPUT_FLAG_ACK, 'Acknowledge')]
  [FlagName(REQUEST_OPLOCK_INPUT_FLAG_COMPLETE_ACK_ON_CLOSE, 'Complete Acknowledge On Close')]
  TOpLockInputFlags = type Cardinal;

  // WDK::ntifs.h - FSCTL 144 (input)
  [SDKName('REQUEST_OPLOCK_INPUT_BUFFER')]
  TRequestOplockInputBuffer = record
    [Reserved(REQUEST_OPLOCK_CURRENT_VERSION)] StructureVersion: Word;
    StructureLength: Word;
    RequestedOplockLevel: TOpLockLevel;
    Flags: TOpLockInputFlags;
  end;

  [FlagName(REQUEST_OPLOCK_OUTPUT_FLAG_ACK_REQUIRED, 'Acknowledge Required')]
  [FlagName(REQUEST_OPLOCK_OUTPUT_FLAG_MODES_PROVIDED, 'Modes Provided')]
  TOpLockOutputFlags = type Cardinal;

  // WDK::ntifs.h - FSCTL 144 (output)
  [SDKName('REQUEST_OPLOCK_OUTPUT_BUFFER')]
  TRequestOplockOutputBuffer = record
    [Reserved(REQUEST_OPLOCK_CURRENT_VERSION)] StructureVersion: Word;
    StructureLength: Word;
    OriginalOplockLevel: TOpLockLevel;
    NewOplockLevel: TOpLockLevel;
    Flags: TOpLockOutputFlags;
    AccessMode: TAccessMask;
    ShareMode: Word;
  end;

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'WOF_PROVIDER')]
  TWofProvider = (
    WOF_PROVIDER_UNKNOWN = 0,
    WOF_PROVIDER_WIM = 1,
    WOF_PROVIDER_FILE = 2,
    WOF_PROVIDER_CLOUD = 3
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PROVIDER_COMPRESSION')]
  TFileProviderCompression = (
    FILE_PROVIDER_COMPRESSION_XPRESS4K = 0,
    FILE_PROVIDER_COMPRESSION_LZX = 1,
    FILE_PROVIDER_COMPRESSION_XPRESS8K = 2,
    FILE_PROVIDER_COMPRESSION_XPRESS16K = 3
  );

  // WDK::ntifs.h
  [SDKName('WOF_EXTERNAL_INFO')]
  TWofExternalInfo = record
    [Reserved(WOF_CURRENT_VERSION)] Version: Cardinal;
    Provider: TWofProvider;
  end;

  // WDK::ntifs.h - FSCTL 195 (input) & FSCTL 196 (output)
  [SDKName('FILE_PROVIDER_EXTERNAL_INFO_V1')]
  TFileProviderExternalInfoV1 = record
    WofInfo: TWofExternalInfo; // Embedded for convenience
    [Reserved(FILE_PROVIDER_CURRENT_VERSION)] Version: Cardinal;
    Algorithm: TFileProviderCompression;
    Flags: Cardinal;
  end;
  PFileProviderExternalInfoV1 = ^TFileProviderExternalInfoV1;

  { Pipes }

  // WDK::ntifs.h - function numbers corresponding FSCTL_PIPE_* codes
  {$SCOPEDENUMS ON}
  TFsCtlPipeFunction = (
    FSCTL_PIPE_ASSIGN_EVENT = 0,
    FSCTL_PIPE_DISCONNECT = 1,
    FSCTL_PIPE_LISTEN = 2,
    FSCTL_PIPE_PEEK = 3,
    FSCTL_PIPE_QUERY_EVENT = 4,
    FSCTL_PIPE_TRANSCEIVE = 5,
    FSCTL_PIPE_WAIT = 6,
    FSCTL_PIPE_IMPERSONATE = 7,
    FSCTL_PIPE_SET_CLIENT_PROCESS = 8,
    FSCTL_PIPE_QUERY_CLIENT_PROCESS = 9,
    FSCTL_PIPE_GET_PIPE_ATTRIBUTE = 10,
    FSCTL_PIPE_SET_PIPE_ATTRIBUTE = 11,
    FSCTL_PIPE_GET_CONNECTION_ATTRIBUTE = 12,
    FSCTL_PIPE_SET_CONNECTION_ATTRIBUTE = 13,
    FSCTL_PIPE_GET_HANDLE_ATTRIBUTE = 14,
    FSCTL_PIPE_SET_HANDLE_ATTRIBUTE = 15,
    FSCTL_PIPE_FLUSH = 16,
    FSCTL_PIPE_DISABLE_IMPERSONATE = 17,
    FSCTL_PIPE_SILO_ARRIVAL = 18,
    FSCTL_PIPE_CREATE_SYMLINK = 19,
    FSCTL_PIPE_DELETE_SYMLINK = 20,
    FSCTL_PIPE_QUERY_CLIENT_PROCESS_V2 = 21
  );
  {$SCOPEDENUMS OFF}

const
  FSCTL_REQUEST_OPLOCK_LEVEL_1 = $00090000;
  FSCTL_REQUEST_OPLOCK_LEVEL_2 = $00090004;
  FSCTL_REQUEST_BATCH_OPLOCK = $00090008;
  FSCTL_OPLOCK_BREAK_ACKNOWLEDGE = $0009000C;
  FSCTL_OPBATCH_ACK_CLOSE_PENDING = $00090010;
  FSCTL_OPLOCK_BREAK_NOTIFY = $00090014;
  FSCTL_LOCK_VOLUME = $00090018;
  FSCTL_UNLOCK_VOLUME = $0009001C;
  FSCTL_DISMOUNT_VOLUME = $00090020;
  FSCTL_OPLOCK_BREAK_ACK_NO_2 = $00090050;
  FSCTL_REQUEST_FILTER_OPLOCK = $0009005C;
  FSCTL_SD_GLOBAL_CHANGE = $000901F4;
  FSCTL_REQUEST_OPLOCK = $00090240;
  FSCTL_SET_EXTERNAL_BACKING = $0009030C;
  FSCTL_GET_EXTERNAL_BACKING = $00090310;

// WDK::ntifs.h
function NtQueryVolumeInformationFile(
  [in] FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [out, WritesTo] FsInformation: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [in] FsInformationClass: TFsInfoClass
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtSetVolumeInformationFile(
  [in] FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [in, ReadsFrom] FsInformation: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [in] FsInformationClass: TFsInfoClass
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtFsControlFile(
  [in] FileHandle: THandle;
  [in, opt] Event: THandle;
  [in, opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [in] FsControlCode: Cardinal;
  [in, ReadsFrom] InputBuffer: Pointer;
  [in, NumberOfBytes] InputBufferLength: Cardinal;
  [out, WritesTo] OutputBuffer: Pointer;
  [in, NumberOfBytes] OutputBufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Helper functions / macros }

// WDK::ntifs.h
function CTL_FS_CODE(
  [in] Func: TFsCtlFunction;
  [in] Method: TIoControlMethod;
  [in] Access: Cardinal
): Cardinal;

function CTL_PIPE_CODE(
  [in] Func: TFsCtlPipeFunction;
  [in] Method: TIoControlMethod;
  [in] Access: Cardinal
): Cardinal;

function DEVICE_TYPE_FSCTL(
  [in] FsControlCode: Cardinal
): TDeviceType;

function FUNCTION_FROM_FS_FSCTL(
  [in] FsControlCode: Cardinal
): TFsCtlFunction;

function FUNCTION_FROM_PIPE_FSCTL(
  [in] FsControlCode: Cardinal
): TFsCtlPipeFunction;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function CTL_FS_CODE;
begin
  Result := (Cardinal(TDeviceType.FILE_DEVICE_FILE_SYSTEM) shl 16) or
    (Access shl 14) or (Cardinal(Func) shl 2) or Cardinal(Method);
end;

function CTL_PIPE_CODE;
begin
  Result := (Cardinal(TDeviceType.FILE_DEVICE_NAMED_PIPE) shl 16) or
    (Access shl 14) or (Cardinal(Func) shl 2) or Cardinal(Method);
end;

function DEVICE_TYPE_FSCTL;
begin
  Result := TDeviceType((FsControlCode shr 16) and $FFFF);
end;

function FUNCTION_FROM_FS_FSCTL;
begin
  Result := TFsCtlFunction((FsControlCode shr 2) and $FFF);
end;

function FUNCTION_FROM_PIPE_FSCTL;
begin
  Result := TFsCtlPipeFunction((FsControlCode shr 2) and $FFF);
end;

end.
