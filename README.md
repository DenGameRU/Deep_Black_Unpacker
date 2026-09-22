# Deep Black Archive Unpacker (.pack)

A Delphi-based utility designed to analyze the binary structure and extract assets from the proprietary `GameGuiSceneSet.pack` resource files used in the PC game **Deep Black** (2011/2012).

## Features
- **Header Parsing:** Decodes internal variables such as Magic ID (`UWFPVF01`), total file counts, and separate file type counts.
- **Dynamic File Extractor:** Maps unnamed binary resource streams to their original file extensions (`*.dds`, `*.gui`) on the fly based on header block counts.
- **Memory-Safe Extraction:** Allocates dynamic buffers (`FileBuffer[0]`) per file to prevent standard Delphi `I/O Error 998` access violations.
- **Auto-Naming & Cleanup:** Scrubs internal 32-byte name strings of trailing null bytes (`#0`) and exports clean filenames directly to the `Extracted\` folder.

## Archive File Format Specs
The tool reverse-engineers the custom `.pack` format using the following binary offset logic:
1. **Main Header (24 bytes):**
   - 8 bytes: Magic ID Signature (`UWFPVF01`)
   - 4 bytes: Number of distinct file extensions (`NumbOfExt`)
   - 4 bytes: Table block delimiter offset (`UNK`)
   - 4 bytes: Total number of compressed files (`NumbOfFiles`)
   - 4 bytes: Data section offset (`UNK3`)
2. **Extensions Block:** 12 bytes per record (`4 bytes string extension + 4 bytes padding + 4 bytes count`).
3. **File Index Table:** 40 bytes per file record (`32 bytes clean filename string + 4 bytes exact file offset + 4 bytes raw data size`).
4. **Data Clusters:** Sequential raw bytes located at their respective calculated `FileOffset` inside the pack.

## Usage
1. Open the compiled executable and click **Button1**.
2. Select any compatible `.pack` archive file via the dialog box.
3. The program will parse the structure, show the index logs inside the memo frame, and automatically dump all 163 assets into an `Extracted\` directory right next to the utility.

## Original Credits
Developed by **DenGame** (2011-2026). Part of an open-source initiative to preserve classic game engine reverser tools.
