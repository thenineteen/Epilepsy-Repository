%%
%EPILEPSY_2_PDFTOXFA
%   This script will convert a list of files from .pdf to .xfa format.
%   In doing so, this extracts XML-based data from the PDF into an
%   XFA format that is more amenable to subsequent parsing than the PDF.
%   
%   Note that the XFA data is in XML format, but it does not only include
%   the proforma data model, i.e. it still needs parsing into a cleaner
%   format.
%
%   It is quite possible that some files do not convert here, either due to
%   an error in a proforma PDF or because the PDF is not in fact a 
%   pro forma at all (i.e. does not contain any internal data of use);
%   it may fail if the conversion Java program is not found or runs with
%   errors specific to your machine (see below).
%
%   This script therefore produces a list of files which were and were not
%   converted.
%
%   ** NOTE - this script makes use of a Java program. To use this script 
%   at all you WILL NEED TO edit this file so that the path to this 
%   Java utility (pdf2xfa2.jar) is correct. You will also need Java on 
%   your command line **
%
%   ** NOTE - if you receive an error for all of your .pdf files, then
%   almost certainly this is because the Java utility is not found or not
%   working. *
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
clear;

%% ** EDIT THIS PATH ACCORDING TO YOUR LOCAL SETUP **
pdfxfa2jarpath = ...
    '/Volumes/Encrypted/karan_scripts_v2/pdf2xfa2/dist/pdf2xfa2.jar';
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Get a list of files from the previous step
filesIn = importdata('screened_files.txt');
filesOut = {};
errorFilesOut = {};
for i = 1:numel(filesIn)
    try
        [path, name, ext] = fileparts(filesIn{i});
        
        system(['java -jar ', pdfxfa2jarpath,...
                ' ''',filesIn{i},''' ''', fullfile(path, [name, '.xfa']),'''']);
        
        filesOut{i} = fullfile(path, [name, '.xfa']); %#ok<SAGROW>
    catch 
        fprintf('error:\t%s\n', filesIn{i});
        errorFilesOut = [ errorFilesOut filesIn{i} ]; %#ok<AGROW>
    end
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Write out a list of converted (and unconverted/error) files
writetable(table(filesOut'), 'converted_files_xfa.txt',  ...
    'WriteVariableNames', false, 'QuoteStrings' , false);

if(~isempty(errorFilesOut))
writetable(table(errorFilesOut'), 'errors_converted_files_xfa.txt', ...
    'WriteVariableNames', false, 'QuoteStrings' , false);
end