%%
%EPILEPSY_4_XML2XLS
%   This script will convert a list of .xml files from the previous stages
%   to a single Excel (.xlsx) file (as well as a .xml and .csv)
%
%   Note that the approach taken is not necessarily the
%   best way, and a better way may be to use
%   instead a XML transformation language approach such as XLST (XSL
%   transformations). Some example code on how to do this is provided as
%   comments at the bottom of this script.
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
clear;

%  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Get a list of files from the previous step
filesIn = importdata('converted_files_xml.txt');
filesOut = {};
errorFilesOut = {};

out = [];
out.patient = [];
for i = 1:numel(filesIn)
    try
        [path, name, ext] = fileparts(filesIn{i});
        patient = xml_read(filesIn{i});
        out.patient = [ out.patient patient ];
        filesOut{i} = fullfile(path, [name, '.xml']); %#ok<SAGROW>
    catch e
        fprintf('error:\t%s\n', filesIn{i});
        errorFilesOut = [ errorFilesOut filesIn{i} ]; %#ok<AGROW>
    end
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Write out the report as a .xml and .xlsx (Excel) file 
Pref.StructItem = false;
xml_write('report.xml', out, 'report', Pref);
Tout = epilepsyreport2table(out);
writetable(Tout, 'report.xlsx');
writetable(Tout, 'report.csv');

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Write out a list of converted (and unconverted/error) files
writetable(table(filesOut'), 'report_files_xml.txt',  ...
    'WriteVariableNames', false, 'QuoteStrings' , false);

if(~isempty(errorFilesOut))
    writetable(table(errorFilesOut'), 'errors_reported_files_xml.txt',  ...
        'WriteVariableNames', false, 'QuoteStrings' , false);
end

% -------------------------------------------------------------------------
%% Example of using XSLT (Extensible Stylesheet Language Transformations)
% This is an example of how the XML structure can be transformed to e.g.
% HTML using XSLT. The same approach could be used to create e.g. CSV or
% XLST without the need to have big matlab functions like
% epilepsyreport2table()
%
% xslt('report.xml', 'report2html.xsl', 'report.html');
% open('report.html');
