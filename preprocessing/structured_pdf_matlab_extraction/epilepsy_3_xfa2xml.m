%%
%EPILEPSY_3_XFATOXML
%   This script will convert a list of files from .xfa to .xml format.
%
%   In doing so, this extracts the XML-based data from the XFA into another
%   XML structure with a new set of fields populated from the MDT
%   XFA file, with data cleaned and mapped, and additional automatically
%   generated fields.
%
%   The function epilepsyxfa2xml() is the workhorse of this process. This
%   function is quite complex, effectively building a new XML file by
%   populating a blank Matlab structure by searching for specific fields
%   in the XFA. The epilepsyxfa2xml() also contains auxillary functions for
%   parsing and so on. It is this function which would probably need most
%   attention in the future. 
%
%   Note that the approach taken (a Matlab script to look for
%   bespoke fields, parse, write bespoke fields) is not necessarily the
%   best way, and a better (perhaps more future proofed way) may be to use
%   instead a XML transformation language approach such as XLST (XSL 
%   transformations). For more suggestions about this see the file
%   epilepsy_4_xml2xls.m.
%
%   It is quite possible that some files do not convert, either because
%   of an error in a proforma PDF/XFA or because the PDF is not in fact a
%   pro forma at all but it made it this far (but fails because the
%   data is in the wrong structure/because the expected fields are not
%   found).
%
%   This script therefore produces a list of files which were and were not
%   converted.
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%   Edited by Karan Dahele (karandahele@gmail.com)
clear;
addpath('xml_io_tools');

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Get a list of files from the previous step
filesIn = importdata('converted_files_xfa.txt');

% [filename, pathname] = ...
%     uigetfile({'*.xfa'}, 'Select one of more PDFs',  'MultiSelect', 'on');
% filesIn = cellfun(@(f) fullfile(pathname, f), filename, 'UniformOutput', false);

filesOut = {};
errorFilesOut = {};
for i = 1:numel(filesIn)
    [path, name, ext] = fileparts(filesIn{i});
        
%     epilepsyxfa2xml(fullfile(path, [name, '.xfa']), ...
%              fullfile(path, [name, '.xml']));
%         
%     filesOut{i} = fullfile(path, [name, '.xml']);
%     
    try
        [path, name, ext] = fileparts(filesIn{i});
        
        epilepsyxfa2xml(fullfile(path, [name, '.xfa']), ...
             fullfile(path, [name, '.xml']));
        
        filesOut{i} = fullfile(path, [name, '.xml']); %#ok<SAGROW>
    catch e
        fprintf('error:\t%s\n', filesIn{i});
        errorFilesOut = [ errorFilesOut filesIn{i} ]; %#ok<AGROW>
    end
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Write out a list of converted (and unconverted/error) files
writetable(table(filesOut'), 'converted_files_xml.txt',  ...
    'WriteVariableNames', false, 'QuoteStrings' , false);

if(~isempty(errorFilesOut))
writetable(table(errorFilesOut'), 'errors_converted_files_xml.txt',  ...
    'WriteVariableNames', false, 'QuoteStrings' , false);
end