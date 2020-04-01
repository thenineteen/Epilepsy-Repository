%%
%EPILEPSY_1_SCREENFILES
%   This script will help build a list of file names to use in subsequent
%   steps. The file names should all be for the .pdf pro forma.
%   Note this script makes several assumptions about the filenames and size
%   of the .pdf files and so in the future, if the conventions change, this
%   may fail to correctly screen the files.
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
clear;

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Get an initial list of files to filter

% Example 1 - by executing a 'find' system command
%path = '''/Volumes/Data/Data/temp/Telemetry meetings and admission records/Current VT meetings and admission records/VT meetings/VT mtgs 2016/4. April''';
%[ status, result ] = system(['find ', path, ' -type f -wholename "*.pdf"']);
%filesIn = regexp(strtrim(result), '\n', 'split');

% Example 2 - by loading a list of filenames
%filesIn = importdata('in_files.txt');

% Example 3 - by a GUI
[filename, pathname] = ...
    uigetfile({'*.pdf'}, 'Select one of more PDFs',  'MultiSelect', 'on');
filesIn = cellfun(@(f) fullfile(pathname, f), filename, 'UniformOutput', false);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Screen out files matching certain criteria

% Example - exclude files which are smaller or larger in size than
% is expected (i.e. reflecting not an appropriate PDF/file); also
% exclude directories
minSizeBytes = 100 * 1024; % (100kb minimum)
maxSizeBytes = 10  * (1024 * 1024); % (10mb maximum)
rejectIdx = [];
for i=1:numel(filesIn)
    files(i) = dir(filesIn{i});  %#ok<*SAGROW>
    if(files(i).isdir || ...
            files(i).bytes < minSizeBytes || ...
            files(i).bytes > maxSizeBytes)
        fprintf('reject:\t%s\n', fullfile(files(i).folder, files(i).name));
        rejectIdx = [ rejectIdx, i ];  %#ok<*AGROW>
    end
end
filesIn(rejectIdx) = [];

% Example - exclude files which are duplicated by a similar file,
% defined by some criteria of name and date
maxDateDiffSec = 31; % 31 days *NB check that the units of this should be days *
rejectIdx = [];
nfiles = numel(filesIn);
for i=1:nfiles
    [ ~, name_i, ~] = fileparts(filesIn{i});
    file_i = dir(filesIn{i});
    for j=1:nfiles
        [ ~, name_j, ~] = fileparts(filesIn{j});
        file_j = dir(filesIn{j});
        if(j==i) % ignore the very same item
            continue
        else
            % compare the filenames alone (no directory, no extension,
            % ignoring differences in upper/lowercase) using only the
            % minimum number of characters available
            if(strncmpi(name_i, name_j, min(length(name_i),length(name_j))))
                % if there is a match with filenames
                % compare datestamps between the files
                datediff = (file_j.datenum - file_i.datenum);
                
                % if the files are from the very same day (no difference in
                % datadiff), assume that the file with the longer filename
                % should be kept
                if(datediff == 0)
                    if(length(name_j) > length(name_i))
                        rejectIdx = [ rejectIdx i ];
                        fprintf('duplicates:\t%s*rejected*\t%s\n', ...
                            filesIn{i}, filesIn{j});
                    end
                end
                
                % if the duplicate (j) is newer (diff > 0), we shall
                % assume the current file (i) is obsolete, *providing the
                % difference in dates* is not over e.g. 31 days
                % more which would suggest a re-presentation of the case
                if(datediff > 0)
                    % the duplicate (j) is newer than the current file
                    if(datediff < maxDateDiffSec)
                        % the duplicate (j) is newer but not over the
                        % threshold for representation
                        rejectIdx = [ rejectIdx i ];
                        fprintf('duplicates:\t%s*rejected*\t%s\n', ...
                            filesIn{i}, filesIn{j});
                    else
                        fprintf('representation:\t%s*original*\t%s*followup*\n', ...
                            filesIn{j}, filesIn{i});
                    end
                end
            end
        end
    end
end
filesIn(rejectIdx) = [];
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Write out a screened list of files
writetable(table(filesIn'), 'screened_files.txt',  ...
    'WriteVariableNames', false, 'QuoteStrings' , false);
