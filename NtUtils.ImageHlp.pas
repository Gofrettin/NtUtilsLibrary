unit NtUtils.ImageHlp;

{
  This module include various parsing routines for Portable Executable format.
}

interface

{$OVERFLOWCHECKS OFF}

uses
  Ntapi.WinNt, Ntapi.ImageHlp, Ntapi.ntmmapi, NtUtils, DelphiApi.Reflection;

type
  TExportEntry = record
    Name: AnsiString;
    Ordinal: Word;
    [Hex] VirtualAddress: Cardinal;
    Forwards: Boolean;
    ForwardsTo: AnsiString;
  end;
  PExportEntry = ^TExportEntry;

  TImportType = (
    itNormal,
    itDelayed
  );

  TImportTypeSet = set of TImportType;

  TImportEntry = record
    ImportByName: Boolean;
    DelayedImport: Boolean;
    Name: AnsiString;
    Ordinal: Word;
  end;

  TImportDllEntry = record
    DllName: AnsiString;
    [Hex] IAT: Cardinal; // Import Address Table RVA
    Functions: TArray<TImportEntry>;
  end;

// Get an NT header of an image
function RtlxGetNtHeaderImage(
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  out NtHeader: PImageNtHeaders
): TNtxStatus;

// Get image bitness
function RtlxGetImageBitness(
  [in] NtHeaders: PImageNtHeaders;
  out Is64Bit: Boolean
): TNtxStatus;

// Get a section that contains a virtual address
function RtlxSectionTableFromVirtualAddress(
  out Section: PImageSectionHeader;
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  VirtualAddress: Cardinal;
  [in, opt] NtHeaders: PImageNtHeaders = nil
): TNtxStatus;

// Get a pointer to a virtual address in an image
function RtlxExpandVirtualAddress(
  out Address: Pointer;
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  VirtualAddress: Cardinal;
  AddressRange: Cardinal;
  [in, opt] NtHeaders: PImageNtHeaders = nil
): TNtxStatus;

// Get a data directory in an image
function RtlxGetDirectoryEntryImage(
  out Directory: PImageDataDirectory;
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  Entry: TImageDirectoryEntry
): TNtxStatus;

// Enumerate exported functions in an image
function RtlxEnumerateExportImage(
  out Entries: TArray<TExportEntry>;
  [in] Base: PImageDosHeader;
  ImageSize: Cardinal;
  MappedAsImage: Boolean
): TNtxStatus;

// Find an export enrty by name
function RtlxFindExportedName(
  const Entries: TArray<TExportEntry>;
  const Name: AnsiString
): PExportEntry;

// Enumerate imported or delayed import of an image
function RtlxEnumerateImportImage(
  out Entries: TArray<TImportDllEntry>;
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  ImportTypes: TImportTypeSet = [itNormal, itDelayed]
): TNtxStatus;

// Relocate an image to a new base address
function RtlxRelocateImage(
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  NewImageBase: NativeUInt;
  MappedAsImage: Boolean
): TNtxStatus;

// Query the image base address that a section would occupy without relocating
function RtlxQueryOriginalBaseImage(
  [Access(SECTION_QUERY)] hSection: THandle;
  const PotentiallyRelocatedMapping: TMemory;
  out Address: Pointer
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, ntapi.ntstatus, NtUtils.SysUtils, NtUtils.Sections,
  NtUtils.Processes, NtUtils.Memory, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxGetNtHeaderImage;
begin
  try
    Result.Location := 'RtlImageNtHeaderEx';
    Result.Status := RtlImageNtHeaderEx(0, Base, ImageSize, NtHeader);
  except
    Result.Location := 'RtlxGetNtHeaderImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;
end;

function RtlxGetImageBitness;
begin
  case NtHeaders.OptionalHeader.Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Is64Bit := False;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Is64Bit := True;
  else
    Result.Location := 'RtlxGetImageBitness';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  end;
end;

function RtlxSectionTableFromVirtualAddress;
var
  i: Integer;
begin
  // Reproduce behavior of RtlSectionTableFromVirtualAddress with more
  // range checks
  
  if not Assigned(NtHeaders) then
  begin
    Result := RtlxGetNtHeaderImage(Base, ImageSize, NtHeaders);

    if not Result.IsSuccess then
      Exit;
  end;

  // Fail with this status if something goes wrong with range checks
  Result.Location := 'RtlxGetSectionImage';
  Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  
  try
    Pointer(Section) := PByte(@NtHeaders.OptionalHeader) +
      NtHeaders.FileHeader.SizeOfOptionalHeader;

    for i := 0 to Integer(NtHeaders.FileHeader.NumberOfSections) - 1 do
    begin
      // Make sure the section is within the image
      if UIntPtr(Section) - UIntPtr(Base) + SizeOf(TImageSectionHeader) >
        ImageSize then
        Exit;

      // Does this virtual address belong to this section?
      if (VirtualAddress >= Section.VirtualAddress) and (VirtualAddress <
        Section.VirtualAddress + Section.SizeOfRawData) then
      begin
        // Yes, it does
        Result.Status := STATUS_SUCCESS;
        Exit;
      end;

      // Go to the next section
      Inc(Section);
    end;

  except
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  // The virtual address is not found within image sections
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxExpandVirtualAddress;
var
  Section: PImageSectionHeader;
begin
  if not MappedAsImage then  
  begin
    if not Assigned(NtHeaders) then
    begin
      Result := RtlxGetNtHeaderImage(Base, ImageSize, NtHeaders);

      if not Result.IsSuccess then
        Exit;
    end;
    
    // Mapped as a file, find a section that contains this virtual address
    Result := RtlxSectionTableFromVirtualAddress(Section, Base, ImageSize,
      VirtualAddress, NtHeaders);

    if not Result.IsSuccess then
      Exit;

    // Compute the address
    Address := PByte(Base) + Section.PointerToRawData - Section.VirtualAddress +
      VirtualAddress;
  end
  else
    Address := PByte(Base) + VirtualAddress; // Mapped as image
  
  // Make sure the address is within the image
  if (UIntPtr(Address) + AddressRange - UIntPtr(Base) > ImageSize) or
    (UIntPtr(Address) < UIntPtr(Base)) then
  begin
    Result.Location := 'RtlxExpandVirtualAddress';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  end
  else
    Result.Status := STATUS_SUCCESS;
end;

function RtlxGetDirectoryEntryImage;
var
  Header: PImageNtHeaders;
begin
  // We are going to reproduce behavior of RtlImageDirectoryEntryToData,
  // but with more range checks

  Result := RtlxGetNtHeaderImage(Base, ImageSize, Header);

  if not Result.IsSuccess then
    Exit;
    
  // If something goes wrong, fail with this status
  Result.Location := 'RtlxGetDirectoryEntryImage';
  Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  
  try    
    // Get data directory
    case Header.OptionalHeader.Magic of
      IMAGE_NT_OPTIONAL_HDR32_MAGIC:
        Directory := @Header.OptionalHeader32.DataDirectory[Entry];

      IMAGE_NT_OPTIONAL_HDR64_MAGIC:
        Directory := @Header.OptionalHeader64.DataDirectory[Entry];
    else
      // Unknown executable architecture, fail
      Exit;
    end;

    // Make sure we read data within the image
    if UIntPtr(Directory) + SizeOf(TImageDataDirectory) - UIntPtr(Base) >
      ImageSize then
      Exit;
  except
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function GetAnsiString(
  [in] Start: PAnsiChar;
  [in] Boundary: Pointer
): AnsiString;
var
  Finish: PAnsiChar;
begin
  Finish := Start;

  while (Finish < Boundary) and (Finish^ <> #0) do
    Inc(Finish);

  SetString(Result, Start, UIntPtr(Finish) - UIntPtr(Start));
end;

function RtlxEnumerateExportImage;
var
  Header: PImageNtHeaders;
  ExportData: PImageDataDirectory;
  ExportDirectory: PImageExportDirectory;
  Names, Functions: ^TAnysizeArray<Cardinal>;
  Ordinals: ^TAnysizeArray<Word>;
  i: Integer;
  Name: PAnsiChar;
begin
  Result := RtlxGetNtHeaderImage(Base, ImageSize, Header);

  if not Result.IsSuccess then
    Exit;

  // Find export directory data 
  Result := RtlxGetDirectoryEntryImage(ExportData, Base, ImageSize,
    MappedAsImage, IMAGE_DIRECTORY_ENTRY_EXPORT);

  if not Result.IsSuccess then
    Exit;
      
  try      
    // Check if the image has any exports
    if ExportData.VirtualAddress = 0 then
    begin
      // Nothing to parse, exit
      SetLength(Entries, 0);
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;
    
    // Make sure export directory has appropriate size
    if ExportData.Size < SizeOf(TImageExportDirectory) then
    begin
      Result.Location := 'RtlxEnumerateExportImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;
    
    // Obtain a pointer to the export directory
    Result := RtlxExpandVirtualAddress(Pointer(ExportDirectory), Base,
      ImageSize, MappedAsImage, ExportData.VirtualAddress,
      SizeOf(TImageExportDirectory), Header);

    if not Result.IsSuccess then
      Exit;
    
    // Get an address of names
    Result := RtlxExpandVirtualAddress(Pointer(Names), Base, ImageSize,
      MappedAsImage, ExportDirectory.AddressOfNames,
      ExportDirectory.NumberOfNames * SizeOf(Cardinal), Header);

    if not Result.IsSuccess then
      Exit;

    // Get an address of name ordinals
    Result := RtlxExpandVirtualAddress(Pointer(Ordinals), Base, ImageSize,
      MappedAsImage, ExportDirectory.AddressOfNameOrdinals,
      ExportDirectory.NumberOfNames * SizeOf(Word), Header);

    if not Result.IsSuccess then
      Exit;

    // Get an address of functions
    Result := RtlxExpandVirtualAddress(Pointer(Functions), Base, ImageSize,
      MappedAsImage, ExportDirectory.AddressOfFunctions,
      ExportDirectory.NumberOfFunctions * SizeOf(Cardinal), Header);

    if not Result.IsSuccess then
      Exit;

    // Fail with this status if something goes wrong
    Result.Location := 'RtlxEnumerateExportImage';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    // Ordinals can reference only up to 65k exported functions
    if ExportDirectory.NumberOfFunctions > High(Word) then
      Exit;

    SetLength(Entries, ExportDirectory.NumberOfNames);

    for i := 0 to High(Entries) do
    begin
      Entries[i].Ordinal := Ordinals{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
    
      // Get a pointer to a name
      Result := RtlxExpandVirtualAddress(Pointer(Name), Base, ImageSize,
        MappedAsImage, Names{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, 0, Header);

      if Result.IsSuccess then
        Entries[i].Name := GetAnsiString(Name, PByte(Base) + ImageSize);
    
      // Each ordinal is an index inside an array of functions
      if Entries[i].Ordinal >= ExportDirectory.NumberOfFunctions then
        Continue;
      
      Entries[i].VirtualAddress :=
        Functions{$R-}[Ordinals[i]]{$IFDEF R+}{$R+}{$ENDIF};

      // Forwarded functions have the virtual address in the same section as
      // the export directory
      Entries[i].Forwards := (Entries[i].VirtualAddress >=
        ExportData.VirtualAddress) and (Entries[i].VirtualAddress <
        ExportData.VirtualAddress + ExportData.Size);

      if Entries[i].Forwards then
      begin
        // In case of forwarding the address actually points to the target name
        Result := RtlxExpandVirtualAddress(Pointer(Name), Base, ImageSize,
          MappedAsImage, Entries[i].VirtualAddress, 0, Header);
          
        if Result.IsSuccess then        
          Entries[i].ForwardsTo := GetAnsiString(Name, PByte(Base) + ImageSize);
      end;

      { TODO: add range checks to see if the VA is within the image. Can't
        simply compare the VA to the size of an image that is mapped as a file,
        though. }
    end;
  except
    Result.Location := 'RtlxEnumerateExportImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function RtlxFindExportedName;
var
  Index: Integer;
begin
  // Export entries are sorted, use fast binary search
  Index := TArray.BinarySearchEx<TExportEntry>(Entries,
    function (const Entry: TExportEntry): Integer
    begin
      Result := RtlxCompareAnsiStrings(Entry.Name, Name, True);
    end
  );

  if Index < 0 then
    Result := nil
  else
    Result := @Entries[Index];
end;

// A worker function for enumerating image import
function RtlxpEnumerateImportImage(
  out Entries: TArray<TImportDllEntry>;
  [in] Base: PImageDosHeader;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  ImportType: TImportType
): TNtxStatus;
const
  IMAGE_DIRECTORY: array [TImportType] of TImageDirectoryEntry = (
    IMAGE_DIRECTORY_ENTRY_IMPORT, IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT
  );
  DESCRIPTOR_SIZE: array [TImportType] of Cardinal = (
    SizeOf(TImageImportDescriptor), SizeOf(TImageDelayLoadDescriptor)
  );
var
  Header: PImageNtHeaders;
  ImportData: PImageDataDirectory;
  ImportDescriptor: PImageImportDescriptor;
  DelayImportDescriptor: PImageDelayLoadDescriptor absolute ImportDescriptor;
  Is64Bit: Boolean;
  UnboundIAT: Pointer;
  DllNameRVA, TableRVA, IATEntrySize: Cardinal;
  pDllName: PAnsiChar;
  ByName: PImageImportByName;
label
  Fail;
begin
  Result := RtlxGetNtHeaderImage(Base, ImageSize, Header);

  if not Result.IsSuccess then
    Exit;

  // Find import directory data
  Result := RtlxGetDirectoryEntryImage(ImportData, Base, ImageSize,
    MappedAsImage, IMAGE_DIRECTORY[ImportType]);

  if not Result.IsSuccess then
    Exit;

  try
    // Check if the image has any imports
    if ImportData.VirtualAddress = 0 then
    begin
      // Nothing to parse, exit
      SetLength(Entries, 0);
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // Make sure import directory has appropriate size
    if ImportData.Size < DESCRIPTOR_SIZE[ImportType] then
    begin
      Result.Location := 'RtlxEnumerateImportImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;

    // Obtain a pointer to the import directory
    Result := RtlxExpandVirtualAddress(Pointer(ImportDescriptor), Base,
      ImageSize, MappedAsImage, ImportData.VirtualAddress,
      DESCRIPTOR_SIZE[ImportType], Header);

    SetLength(Entries, 0);

    // The structure of import depends on image bitness
    Result := RtlxGetImageBitness(Header, Is64Bit);

    if not Result.IsSuccess then
      Exit;

    if Is64Bit then
      IATEntrySize := SizeOf(UInt64)
    else
      IATEntrySize := SizeOf(Cardinal);

    while ((ImportType = itNormal) and (ImportDescriptor.Name <> 0)) or
       ((ImportType = itDelayed) and (DelayImportDescriptor.DllNameRVA <> 0)) do
    begin
      SetLength(Entries, Length(Entries) + 1);

      with Entries[High(Entries)] do
      begin
        if ImportType = itNormal then
          DllNameRVA := ImportDescriptor.Name
        else
          DllNameRVA := DelayImportDescriptor.DllNameRVA;

        // Locate the DLL name string
        Result := RtlxExpandVirtualAddress(Pointer(pDllName), Base, ImageSize,
          MappedAsImage, DllNameRVA, SizeOf(AnsiChar), Header);

        if not Result.IsSuccess then
          Exit;

        // Save DLL name and IAT RVA
        DllName := GetAnsiString(pDllName, PByte(Base) + ImageSize);

        if ImportType = itNormal then
        begin
          IAT := ImportDescriptor.FirstThunk;
          TableRVA := ImportDescriptor.OriginalFirstThunk;
        end
        else
        begin
          IAT := DelayImportDescriptor.ImportAddressTableRVA;
          TableRVA := DelayImportDescriptor.ImportNameTableRVA;
        end;

        // Locate import name table
        Result := RtlxExpandVirtualAddress(Pointer(UnboundIAT), Base, ImageSize,
          MappedAsImage, TableRVA, IATEntrySize, Header);

        if not Result.IsSuccess then
          Exit;

        // Iterate through the name table
        while (Is64Bit and (UInt64(UnboundIAT^) <> 0)) or
          (not Is64Bit and (Cardinal(UnboundIAT^) <> 0)) do
        begin
          SetLength(Functions, Length(Functions) + 1);

          with Functions[High(Functions)] do
          begin
            DelayedImport := ImportType = itDelayed;

            if Is64Bit then
              ImportByName := UInt64(UnboundIAT^) and (UInt64(1) shl 63) = 0
            else
              ImportByName := Cardinal(UnboundIAT^) and (1 shl 31) = 0;

            if ImportByName then
            begin
              // Locate function name
              Result := RtlxExpandVirtualAddress(Pointer(ByName), Base,
                ImageSize, MappedAsImage, Cardinal(UnboundIAT^),
                SizeOf(TImageImportByName), Header);

              if not Result.IsSuccess then
                Exit;

              Name := GetAnsiString(@ByName.Name[0], PByte(Base) + ImageSize);
            end
            else
              Ordinal := Word(UnboundIAT^) // Import by ordinal
          end;

          UnboundIAT := PByte(UnboundIAT) + IATEntrySize;

          // Make sure the next element belongs to the image
          if PByte(UnboundIAT) + IATEntrySize > PByte(Base) + ImageSize then
            goto Fail;
        end;

        // Make sure the whole IAT section for this DLL belongs to the image
        if MappedAsImage and (IAT + IATEntrySize * Cardinal(Length(Functions)) >
          ImageSize) then
          goto Fail;
      end;

      // Move to the next DLL
      if ImportType = itNormal then
        Inc(ImportDescriptor)
      else
        Inc(DelayImportDescriptor);

      // Make sure it is still within the image
      if UIntPtr(ImportDescriptor) - UIntPtr(Base) >= ImageSize then
      begin
      Fail:
        Result.Location := 'RtlxEnumerateImportImage';
        Result.Status := STATUS_INVALID_IMAGE_FORMAT;
        Exit;
      end;
    end;
  except
    Result.Location := 'RtlxEnumerateImportImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function RtlxEnumerateImportImage;
var
  PerTypeEntries: TArray<TImportDllEntry>;
  ImportType: TImportType;
begin
  Entries := nil;

  for ImportType in ImportTypes do
  begin
    Result := RtlxpEnumerateImportImage(PerTypeEntries, Base, ImageSize,
      MappedAsImage, ImportType);

    if not Result.IsSuccess then
    begin
      Entries := nil;
      Exit;
    end;

    Entries := Entries + PerTypeEntries;
  end;
end;

function RtlxRelocateImage;
var
  NtHeaders: PImageNtHeaders;
  RelocationDelta: UInt64;
  RelocDirectory: PImageDataDirectory;
  Entry: PImageBaseRelocation;
  Boundary, TargetPage, Target: Pointer;
  TypeOffset: PImageRelocationTypeOffset;
  ProtectionReverter, NextPageProtectionReverter: IAutoReleasable;
begin
  // Locate the header
  Result := RtlxGetNtHeaderImage(Base, ImageSize, NtHeaders);

  if not Result.IsSuccess then
    Exit;

  {$Q-}{$R-}
  RelocationDelta := NewImageBase - NtHeaders.OptionalHeader.ImageBase;
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

  if RelocationDelta = 0 then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Find relocations
  Result := RtlxGetDirectoryEntryImage(RelocDirectory, Base, ImageSize,
    MappedAsImage, IMAGE_DIRECTORY_ENTRY_BASERELOC);

  if not Result.IsSuccess then
    Exit;

  if RelocDirectory.Size = 0 then
  begin
    Result.Location := 'RtlxRelocateImage';
    Result.Status := STATUS_ILLEGAL_DLL_RELOCATION;
    Exit;
  end;

  // Get the start of the relocations block
  Result := RtlxExpandVirtualAddress(Pointer(Entry), Base, ImageSize,
    MappedAsImage, RelocDirectory.VirtualAddress, RelocDirectory.Size,
    NtHeaders);

  if not Result.IsSuccess then
    Exit;

  UIntPtr(Boundary) := UIntPtr(Entry) + RelocDirectory.Size;

  while UIntPtr(Entry) <= UIntPtr(Boundary) - SizeOf(TImageBaseRelocation) do
  begin
    // Make sure we don't skip the end of the relocation block
    if UIntPtr(Entry) + Entry.SizeOfBlock > UIntPtr(Boundary) then
    begin
      Result.Location := 'RtlxRelocateImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;

    // Find the start of the target page
    Result := RtlxExpandVirtualAddress(TargetPage, Base, ImageSize,
      MappedAsImage, Entry.VirtualAddress, PAGE_SIZE, NtHeaders);

    if not Result.IsSuccess then
      Exit;

    if MappedAsImage then
    begin
      // Make sure the memory is writable
      Result := NtxProtectMemoryAuto(NtxCurrentProcess, TargetPage, PAGE_SIZE,
        PAGE_READWRITE, ProtectionReverter);

      if not Result.IsSuccess then
        Exit;
    end;

    TypeOffset := @Entry.TypeOffsets[0];

    while UIntPtr(TypeOffset) < UIntPtr(Entry) + Entry.SizeOfBlock do
    begin
      // Compute the where and which type of relocation to apply
      Target := PByte(TargetPage) + TypeOffset.Offset;

      // If the relocation spans on the next page, make it writable as well
      if MappedAsImage and TypeOffset.SpansOnNextPage then
      begin
        Result := NtxProtectMemoryAuto(NtxCurrentProcess,
          PByte(TargetPage) + PAGE_SIZE, PAGE_SIZE, PAGE_READWRITE,
          NextPageProtectionReverter);

        if not Result.IsSuccess then
          Exit;
      end;

      {$Q-}{$R-}
      case TypeOffset.&Type of
        IMAGE_REL_BASED_ABSOLUTE:
          ; // Nothing to do

        IMAGE_REL_BASED_HIGH:
          Inc(Word(Target^), Word(RelocationDelta shr 16));

        IMAGE_REL_BASED_LOW:
          Inc(Word(Target^), Word(RelocationDelta));

        IMAGE_REL_BASED_HIGHLOW:
          Inc(Cardinal(Target^), Cardinal(RelocationDelta));

        IMAGE_REL_BASED_DIR64:
          Inc(UInt64(Target^), UInt64(RelocationDelta));
      else
        Result.Location := 'RtlxRelocateImage';
        Result.Status := STATUS_NOT_SUPPORTED;
        Exit;
      end;
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

      Inc(TypeOffset);
    end;

    Inc(PByte(Entry), Entry.SizeOfBlock);
  end;

  if MappedAsImage then
  begin
    // Make the header writable if necessary
    Result := NtxProtectMemoryAuto(NtxCurrentProcess, NtHeaders,
      UIntPtr(@PImageNtHeaders(nil).OptionalHeader.SectionAlignment),
      PAGE_READWRITE, ProtectionReverter);

    if not Result.IsSuccess then
      Exit;
  end;

  // Adjust the image base in the header
  case NtHeaders.OptionalHeader.Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC:
      NtHeaders.OptionalHeader32.ImageBase := Cardinal(NewImageBase);

    IMAGE_NT_OPTIONAL_HDR64_MAGIC:
      NtHeaders.OptionalHeader64.ImageBase := NewImageBase;
  end;
end;

function RtlxQueryOriginalBaseImage;
var
  Info: TSectionImageInformation;
  NtHeaders: PImageNtHeaders;
begin
  // Determine the intended entrypoint address of the known DLL
  Result := NtxSection.Query(hSection, SectionImageInformation, Info);

  if not Result.IsSuccess then
    Exit;

  // Find the image header where we can lookup the etrypoint offset
  Result := RtlxGetNtHeaderImage(PotentiallyRelocatedMapping.Address,
    PotentiallyRelocatedMapping.Size, NtHeaders);

  if not Result.IsSuccess then
    Exit;

  // Calculate the original base address
  Address := PByte(Info.TransferAddress) -
    NtHeaders.OptionalHeader.AddressOfEntryPoint;
end;

end.
