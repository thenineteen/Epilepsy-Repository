%%
%EPILEPSY_GO
%   This script will run each script in the pipeline. See README.txt
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
epilepsy_1_screenfiles;
fprintf('Screened files\n');
epilepsy_2_pdf2xfa;
fprintf('Converted pdf to xfa\n');
epilepsy_3_xfa2xml;
fprintf('Converted xfa to xml\n');
% epilepsy_4_xml2xls;
% fprintf('Converted xml to xls\n');