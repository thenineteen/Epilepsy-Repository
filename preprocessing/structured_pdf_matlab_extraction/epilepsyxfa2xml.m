function out = epilepsyxfa2xml(filename, outfilename)
%%
%EPILEPSYXFA2XML Process an epilepsy MDT XFA into a structure and XML form.
%   OUT = EPILEPSYXFA2XML(FILENAME) returns OUT, a structure representing
%   the data from the epilepsy MDT XFA file specified by the string
%   FILENAME.
%
%   If the file specified by FILENAME is not in the current directory, or
%   in a directory on the MATLAB path, specify the full pathname.
%
%   This function is quite complex, effectively building a new XML file by
%   populating a blank Matlab structure (out) by searching for specific
%   fields in the XFA data.
%
%   The return value OUT is a structure with fields populated from the MDT
%   XFA file, with data cleaned and mapped, and additional automatically
%   generated fields.
%
%   OUT = EPILEPSYXFA2XML(FILENAME, OUTFILENAME) writes the OUT structure
%   as XML to the file specified by the string OUTFILENAME.
%
%   Example
%   -------
%       out = epilepsyxfa2xml('mdt_BLOGGS_JOE_12345_outcome.xfa');
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%   Edited by Karan Dahele (karandahele@gmail.com)

in  = xml_read(filename);
out = struct();

% -------------------------------------------------------------------------
% Metadata
out.meta.version        = '0.1';
out.meta.createdDate    = datetime();
out.meta.modifiedDate   = '';
out.meta.notes          = '';
out.meta.inputFile      = filename;

% -------------------------------------------------------------------------
% Meeting
out.meeting.title       = totext(in, 'Title');
out.meeting.date        = todate(2000, in, 'MeetingDate');

% -------------------------------------------------------------------------
% Attendees

% Attendee names that appear within XFA fields (each tails 'att', e.g. attkoepp)
attendeeCheckList = {'baxendale', 'brownstone', 'diehl', 'duncan', 'eriksson', ...
    'foong', 'heaney', 'mcevoy', 'misrrocchi', 'koepp', 'sullivan', ...
    'rugggun', 'sander', 'shorvon', 'sisodiya', 'thompson', 'walker', ...
    'wehner' };

% Make a checklist of yes/no fields for each possible attendee (above)
% whilst also creating a written list of attendee names
out.meeting.attendees.checklisted = {};

for i = 1:numel(attendeeCheckList)
    if(totext(in, ['att', attendeeCheckList{i}]))
        out.meeting.attendees.checklisted = ...
            [out.meeting.attendees.checklisted ...
            [upper(attendeeCheckList{i}(1)),attendeeCheckList{i}(2:end)]];
        out.meeting.attendees.checklist.(attendeeCheckList{i}) = 0;
    else
        out.meeting.attendees.checklist.(attendeeCheckList{i}) = 1;
    end
end

out.meeting.attendees.text   = strjoin(out.meeting.attendees.checklisted);
out.meeting.attendees.others = totext(in, 'atatothers');
out.meeting.attendees.count  = length(out.meeting.attendees.checklisted);

% -------------------------------------------------------------------------
% Authors
out.authors.preparedBy    = totext(in, 'prepared');
out.authors.reviewedBy    = totext(in, 'conslock');
out.authors.lockedBy      = totext(in, 'locked');

% -------------------------------------------------------------------------
% Demographics
out.demographics.name          = totext(in, 'Name');
out.demographics.dateOfBirth   = todate(1900, in, 'DOB');

theid  = totext(in, 'Number');
if(~isnumeric(theid))
    out.demographics.identifier    = erase(char(theid), ' ');
else
    out.demographics.identifier = theid;
end

out.demographics.handedness    = totext(in, 'Chirality');
if(~isempty(out.demographics.dateOfBirth))
    out.demographics.age           = ...
        years(out.meeting.date - out.demographics.dateOfBirth);
else
    out.demographics.age = '';
end
% -------------------------------------------------------------------------
% Consultant
out.consultant  = totext(in, 'Consultant');

% -------------------------------------------------------------------------
% Referrer
out.referrer    = totext(in, 'Referrer');

% -------------------------------------------------------------------------
% Antecedent history
out.antecedents.hadAbnormalPregnancy       = tobool(in, 'Pregnancy');
out.antecedents.hadAbnormalDelivery        = tobool(in, 'Delivery');
out.antecedents.hadFebrileConvulsions      = tobool(in, 'Febrile');
out.antecedents.hadChildhoodHeadInjury     = tobool(in, 'Childhead');
out.antecedents.hadChildhoodCNSInfections  = tobool(in, 'Childinfections');
out.antecedents.hadDelayedMilestones       = tobool(in, 'Milestones');
out.antecedents.antecedentsCount = sum(...
    [out.antecedents.hadAbnormalPregnancy, ...
    out.antecedents.hadAbnormalDelivery, ...
    out.antecedents.hadFebrileConvulsions, ...
    out.antecedents.hadChildhoodHeadInjury, ...
    out.antecedents.hadChildhoodCNSInfections, ...
    out.antecedents.hadDelayedMilestones  ]);
out.antecedents.antecedentsText                       = totext(in, 'Anthistdetails');

% -------------------------------------------------------------------------
% Clinical details and background
out.clinicalDetails = totext(in, 'ClinDetailsText');

out.background.hadInjuries             = tobool(in, 'Injuries');
out.background.injuriesText            = totext(in, 'InjDetails');
out.background.hadStatus               = tobool(in, 'Status');
out.background.statusText              = totext(in, 'StatusDetails');
out.background.pastMedicalHistory      = totext(in, 'PMHDetails');
out.background.pastPsychiatricHistory  = totext(in, 'PSHDetails');
out.background.familyHistory           = totext(in, 'FHDetails');
out.background.socialHistory           = totext(in, 'SHDetails');

% -------------------------------------------------------------------------
% Examination
out.examination.generalExaminationStatus  = totext(in, 'Examination');
out.examination.generalExaminationText    = totext(in, 'Examdetails');
out.examination.neurologicalExaminationStatus = totext(in, 'Nexamination');
out.examination.neurologicalExaminationText   = totext(in, 'Nexamdetails');

% -------------------------------------------------------------------------
% Investigations
out.investigations.eeg.status       = totext(in, 'EEGrow', 'EEGlist');
out.investigations.eeg.text         = totext(in, 'EEGrow', 'Cell4');
out.investigations.vt.status        = totext(in, 'VTRow', 'VTlist');
out.investigations.vt.text          = totext(in, 'VTRow', 'Cell4');
out.investigations.mri.status       = totext(in, 'MRIrow', 'MRIlist');
out.investigations.mri.text         = totext(...
    findfieldattr(in, 'name', 'MRIrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.fmri.status      = totext(in, 'fMRIrow', 'fMRIlist');
out.investigations.fmri.text        = totext(...
    findfieldattr(in, 'name', 'fMRIrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.fmriEeg.status   = totext(in, 'fMRIEEGrow', 'fmrieeglist');
out.investigations.fmriEeg.text     = totext(...
    findfieldattr(in, 'name', 'fMRIEEGrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.fdgPet.status    = totext(in, 'fdgpetrow', 'fdgpetlist');
out.investigations.fdgPet.text      = totext(...
    findfieldattr(in, 'name', 'fdgpetrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.meg.status       = totext(in, 'megrow', 'meglist');
out.investigations.meg.text         = totext(...
    findfieldattr(in, 'name', 'megrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.spect.status     = totext(in, 'spectrow', 'spectlist');
out.investigations.spect.text       = totext(...
    findfieldattr(in, 'name', 'spectrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.psychology.status= totext(in, 'Psychrow', 'psychlist');
out.investigations.psychology.text  = totext(...
    findfieldattr(in, 'name', 'Psychrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.psychiatry.status= totext(in, 'Psychirow', 'psychilist');
out.investigations.psychiatry.text  = totext(...
    findfieldattr(in, 'name', 'Psychirow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.intracranials.status = totext(in, 'Intracranialrow', 'Intralist');
out.investigations.intracranials.text   = totext(...
    findfieldattr(in, 'name', 'Intracranialrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.wada.status      = totext(in, 'Wadarow', 'Wadalist');
out.investigations.wada.text        = totext(...
    findfieldattr(in, 'name', 'Wadarow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');
out.investigations.otherTests.status= totext(in, 'Otherrow', 'otherlist');
out.investigations.otherTests.text  = totext(...
    findfieldattr(in, 'name', 'Otherrow', 'form', 'subform', 'subform', ...
    'subform', 'subform'), 'field', 'value', 'text');

% -------------------------------------------------------------------------
% Discussion
out.discussion.previouslyDiscussed = tobool(in, 'discussionform', 'Previous');
out.discussion.chair               = totext(in, 'discussionform', 'Chaired');
out.discussion.reviews             = totext(in, 'discussionform', 'Reviews');

% -------------------------------------------------------------------------
% Conclusion
out.conclusion.zone.text = totext(in, 'Zone');
out.conclusion.plan      = totext(in, 'Plan');
out.conclusion.outcome   = totext(in, 'Outcome');

% Define possible zones and pattern matches for each
zoneCheckList = {
    {'temporal', '\<(temporal)\>|temporo'}, ...
    {'frontal', '\<(frontal)\>|fronto'} ...
    };

% Make a checklist of yes/no fields for each possible zone (above)
str = out.conclusion.zone.text;
for i = 1:numel(zoneCheckList)
    out.conclusion.zone.checklist.(zoneCheckList{i}{1}) =  ...
        ~isempty(regexpi(str, ...
        zoneCheckList{i}{2}));
end
% -------------------------------------------------------------------------
% Current events
sx = findfield(in, 'supersuperrow');

for i = 1:length(sx)
    cl = findfield(sx(i), 'classtab');
    for j = 1:length(cl)
        out.events.event(i).classification{j} = ...
            totext(cl(j), 'classification');
    end
    
    % remove any empty steps
    out.events.event(i).classification(find(...
        cellfun(@(s) isempty(s), out.events.event(1).classification))) = []; %#ok<FNDSB>
    
    out.events.event(i).classificationLength = length(out.events.event(i).classification);
    out.events.event(i).classificationText   = ...
        strjoin(out.events.event(i).classification, ' ');
    
    out.events.event(i).description       = totext(sx(i), 'superclasstabrow2', 'Cell2');
    out.events.event(i).lateralizingSigns = totext(sx(i), 'sclasstabrow3', 'Cell2');
    out.events.event(i).duration          = totext(sx(i), 'sclasstabrow4', 'Cell2');
    out.events.event(i).frequency         = totext(sx(i), 'sclasstabrow5', 'Cell2');
    out.events.event(i).postictally       = totext(sx(i), 'sclasstabrow6', 'Cell2');
    out.events.event(i).triggers          = totext(sx(i), 'sclasstabrow7', 'Cell2');
end

out.events.maxClassificationLength = max([out.events.event.classificationLength]);
out.events.count = length(sx);
out.events.allText = '';

% Make a single field with all event descriptors in
for i = 1:out.events.count
    out.events.allText = sprintf(['%s\n%d\n%s\nDescription: %s\n' ,...
        'Lateralizing signs: %s\n', ...
        'Duration: %s\nFrequency: %s\nPost-ictally: %s\nTriggers %s\n'], ...
        out.events.allText, i, out.events.event(i).classificationText, ...
        out.events.event(i).description, ...
        out.events.event(i).lateralizingSigns, ...
        out.events.event(i).duration, ...
        out.events.event(i).frequency, ...
        out.events.event(i).postictally, ...
        out.events.event(i).triggers);
end

% Make a checklist of yes/no fields for each possible drug (above)
% based on fields created now, for both current and previous drugs
eventCheckList = defineEventCheckList();
% disp(eventCheckList);
for i = 1:numel(eventCheckList)
    if(find(cell2mat(strfind(lower({ out.events.event.classificationText }), lower(eventCheckList{i}{2})))))
        out.events.checklist.(eventCheckList{i}{1}) = 1;
    else
        out.events.checklist.(eventCheckList{i}{1}) = 0;
    end
end

%% Make a distinct data structure that captures the events in the form
% of a series of checklist columns but rather than binary 0/1 (for if it
% occured in any seizure, it instead lists [0,1,0] if the phenomenon occurred
% as the 1st step of the 2nd event
eventCheckList = defineEventCheckList();

maxEventCount = 8;

% make a set of blanks
for i = 1:numel(eventCheckList)
    out.events.checklistArr.(['arr',eventCheckList{i}{1}]) = zeros(1,maxEventCount);
end
for j = 1:out.events.count
    event = out.events.event(j);
    
    if(isempty(event) || event.classificationLength == 0)
        continue;
    end
    
    % First screen each event to ensure it only contains valid parts
    % of the classification system
    for k = 1:event.classificationLength
        found = false;
        for l=1:numel(eventCheckList)
            if(strcmpi(strtrim(event.classification{k}), strtrim([eventCheckList{l}{2}, ' >'])))
                found = true;
                break;
            elseif (strcmpi(strtrim(event.classification{k}), eventCheckList{l}{2}))
                found = true;
                break;
            end
        end
        
        if(~found)
            disp([filename, 'Not found: ', event.classification{k},] );
            break;
        else
            out.events.checklistArr.(['arr',eventCheckList{l}{1}])(j) = k;
        end
    end
    
    if(~found)
        disp(['This event had unknown classification step/s']);
        continue;
    end
    
end


% -------------------------------------------------------------------------
% Drugs

% Drug names that appear within XFA fields
drugCheckList = { 'Acetazolamide','Beclamide','Carbamazepine',...
    'Oxcarbazepine','Clobazam','Clonazepam','Eslicarbazepine', 'Ethosuxamide',...
    'Gabapentin','Lacosamide','Levetiracetam','Lamotrigine',...
    'Ospolot','Phenobarbitone','Phenytoin','Pregabalin',...
    'Primidone','Retigabine','Rufinamide','Tiagabine',...
    'Topiramate','Valproate','Vigabatrin','Zonisamide'};

% Flags for total checklist to indicate if drug Currently or Previously
% used (or neither)
currentFlag = 'C'; previousFlag = 'P'; neitherFlag = ' ';

% Build a record of drugs in different types of structure
drtable = findfield(in, 'Drugtable');
out.drugs.current.drug  = [];
out.drugs.previous.drug = [];

for i = 1:length(drtable.Row1)
    dr.name         = totext(drtable.Row1(i), 'Cell1');
    dr.currentDose  = totext(drtable.Row1(i), 'Cell2');
    dr.previousDose = totext(drtable.Row1(i), 'Cell3');
    dr.comments     = totext(drtable.Row1(i), 'Cell4');
    
    if(~isempty(dr.currentDose) && ...
            isempty(regexp(lower(dr.currentDose), 'stop|stopped|stopping|previous|withdrawn', 'once')) )
        dr.isCurrent = 1;
        out.drugs.current.drug = [ out.drugs.current.drug dr ];
    else
        dr.isCurrent = 0;
        out.drugs.previous.drug = [ out.drugs.previous.drug dr ];
    end
end

if(~isempty(out.drugs.current.drug))
    out.drugs.current.namesText  = strjoin({out.drugs.current.drug.name});
else
    out.drugs.current.namesText  = '';
end


if(~isempty(out.drugs.previous.drug))
    out.drugs.previous.namesText = strjoin({out.drugs.previous.drug.name});
else
    out.drugs.previous.namesText = '';
end

out.drugs.current.text = strjoin(...
    arrayfun(@(d) [d.name, ' ', d.currentDose], ...
    out.drugs.current.drug, 'UniformOutput', false),',');
out.drugs.previous.text = strjoin(...
    arrayfun(@(d) [d.name, ' ', d.currentDose], ...
    out.drugs.previous.drug, 'UniformOutput', false),',');

out.drugs.current.count  = length(out.drugs.current.drug);
out.drugs.previous.count = length(out.drugs.previous.drug);
out.drugs.all.count = out.drugs.current.count + out.drugs.previous.count;

% Make a checklist of yes/no fields for each possible drug (above)
% based on fields created now, for both current and previous drugs

% also include separate counters for counting drugs only in the checklists
out.drugs.current.checklistCount = 0;
out.drugs.previous.checklistCount = 0;
out.drugs.all.checklistCount = 0;

for i = 1:numel(drugCheckList)
    out.drugs.all.checklist.(drugCheckList{i}) = neitherFlag;
    if(~isempty(out.drugs.current.drug) && isempty(regexp(lower(dr.currentDose), 'stop|stopped|stopping|previous|withdrawn', 'once')) ...
            && ~isempty(find(cell2mat(strfind({out.drugs.current.drug.name}, drugCheckList{i})))))
        out.drugs.current.checklist.(drugCheckList{i}) = 1;
        out.drugs.all.checklist.(drugCheckList{i}) = currentFlag;
        
        out.drugs.current.checklistCount = out.drugs.current.checklistCount + 1;
        out.drugs.all.checklistCount = out.drugs.all.checklistCount + 1;
    else
        out.drugs.current.checklist.(drugCheckList{i}) = 0;
    end
    
    if(~isempty(out.drugs.previous.drug) && ~isempty(find(cell2mat(strfind({out.drugs.previous.drug.name}, drugCheckList{i})))))
        out.drugs.previous.checklist.(drugCheckList{i}) = 1;
        out.drugs.all.checklist.(drugCheckList{i}) = previousFlag;
        
        out.drugs.previous.checklistCount = out.drugs.previous.checklistCount + 1;
        out.drugs.all.checklistCount = out.drugs.all.checklistCount + 1;
    else
        out.drugs.previous.checklist.(drugCheckList{i}) = 0;
    end
end

% =========================================================================
%% Parse loaded data

% Guess the gender of the patient based on
[ out.demographics.gender, out.demographics.genderProbability ] = ...
    guessgender(struct2flatstr(out));

% Guess the lateralisation of language from the fMRI report
if(~isempty(out.investigations.fmri.text))
    [ out.investigations.fmri.lateralisation, ...
        out.investigations.fmri.lateralisationProbability ] = ...
        guesslanguagelateralisation(out.investigations.fmri.text);
else
    out.investigations.fmri.lateralisation = '';
    out.investigations.fmri.lateralisationProbability = 0;
end

% =========================================================================
%% Optionally write to an XML file
if(nargin > 1)
    Pref.CellItem = false;
    Pref.StructItem = false;
    xml_write(outfilename, out, 'case', Pref);
end

end

% =========================================================================


function B = tobool(S, varargin)
%%
%TOTEXT Return a boolean (logical) value for the field F within structure S
%
B = (totext(S, varargin{:}));
end


% -------------------------------------------------------------------------
function [GENDER P] = guessgender(str)
%%
%GUESSGENDER Guess the gender generally occuring in a string
%   GENDER = GUESSGENDER(STR) returns GENDER, a string (either 'Male' or
%   'Female')
%
%   [ GENDER P ] = GUESSGENDER(STR) returns GENDER, and an estimate of the
%   probability P (based on ratios of counting of gender-specific words) of
%   this guess being valid.
%
%   Notes
%   -----
%
nmale   = length(regexpi((str), '\<(he|him|his|man|male|boy)\>'));
nfemale = length(regexpi((str), '\<(she|her|woman|female|girl)\>'));

if nmale >= nfemale
    GENDER = 'Male';
    P = nmale/(nmale+nfemale);
else
    GENDER = 'Female';
    P = nfemale/(nfemale+nmale);
end
end

function D = todate(pivot, S, varargin)
%%
%TODATE Return a datetime  value for the field F within structure S
%
str = lower(totext(S, varargin{:}));

str = erase(str, {'st', 'nd', 'rd', 'th'});
str = strrep(str, '[', '(');
str = strrep(str, ']', ')');

if(strfind(str, '(')) %#ok<STRIFCND>
    % deal with the case where there is e.g. '(38M)' written in the
    % input string
    str = strtrim(str(1:strfind(str, '(')-1));
end

str = strrep(str, '/', '.');
str = strrep(str, '-', '.');

try
    D = datetime(str, 'InputFormat', 'd.M.yy', 'PivotYear', pivot);
catch
    try
        D = datetime(str, 'InputFormat', 'dd.MM.yyyy', 'PivotYear', pivot);
    catch
        try
            D = datetime(str, 'InputFormat', 'yyyy.MM.dd', 'PivotYear', pivot);
        catch
            try
                D = datetime(str, 'InputFormat', 'dd MMMM yyyy', 'PivotYear', pivot);
            catch
                try
                    D = datetime(str, 'InputFormat', 'dd MMM yyyy', 'PivotYear', pivot);
                catch
                    try
                        str = str(find(~isspace(str))); %#ok<FNDSB>
                        
                        D = datetime(str, 'InputFormat', 'dd.MM.yyyy', 'PivotYear', pivot);
                    catch
                        D = '';
                    end
                end
            end
        end
    end
end
end


function X = totext(S, varargin)
%%
%TOTEXT Return a text value for the field F within structure S
%
try
    X = findfield(S, varargin{:});
    if(ischar(X))
        X(regexp(X,'[\n]'))=[];
        X = strtrim(X);
    end
    if(isempty(X))
        X = '';
    end
catch
    X = ''
end
end

function Y = findfield(S, varargin)
%FINDFIELD Recursively search for all matching fields in a structure by
%   using a variable-length path to the field
%
%   Y = FINDFIELD(S, N1) returns Y, zero or more fields in the structure S
%   with the name N1 to be found at any level/s in S. '' is returned if no
%   matching fields are found.
%
%   Y = FINDFIELD(S, N1, N2) returns the matching fields in S with the name
%   N2, each of which in turn is a child of structure with the name N1. ''
%   is returned if no matching fields are found.
%
%   Y = FINDFIELD(S, N1, N2, N3) returns the matching fields in S with with
%   name N3, each of which in turn is a child of structure N2, in turn a
%   child of a structure named N1.
%
%   Notes ----- This is not guaranteed to work with all Matlab structures
%   and types. Wildcards are not supported.
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
if length(varargin) < 1
    Y = {};
else
    if(numel(S) > 1)
        Y = {};
        for i=1:length(S)
            Y = [ Y findfield(S(i), varargin{:}) ]; %#ok<*AGROW>
        end
    else
        if length(varargin) == 1
            Y = findfield_aux(S, varargin{1});
        else
            Y = {};
            Ys = findfield_aux(S, varargin{1});
            for i=1:length(Ys)
                Y = [ Y findfield(Ys{i}, varargin{2:end}) ]; %#ok<*AGROW>
            end
        end
        
        if(iscell(Y) && numel(Y) == 1)
            Y = cell2mat(Y);
        end
    end
end
end

function Y = findfield_aux(S, F)
%%
%FINDFIELD_AUX As for FINDFIELD but only for a single field name
%
if(~isstruct(S))
    Y = {};
elseif(isfield(S, F))
    Y = { S.(F) } ;
elseif(iscell(S))
    Y = {};
    for x = 1:length(S)
        Y2 = findfield_aux(S{x}, F);
        Y = [Y Y2];
    end
else
    Y = {};
    for z = 1:length(S)
        names = fieldnames(S(z));
        for x = 1:length(names)
            Y2 = findfield_aux(S(z).(names{x}), F);
            Y = [ Y Y2 ];
        end
    end
end
end


function Y = findfieldattr(S, AN, AV, varargin)
%FINDFIELDATTR Recursively search for all matching fields in a structure
%   with an attribute with the specified name and value, and then using
%   the resulting fields, search for matching fields by using a
%   variable-length path to the field, and then finding within any
%   matching structures.
%
%   Note this function requires the node.ATTRIBUTE/node.CONTENT format
%   of structures (see xml_read)
%
%   Y = FINDFIELD(S, AN, AV, N1) returns Y, zero or more fields in the
%   structure S with the name N1 to be found at any level/s in S. ''
%   is returned if no matching fields are found.
%
%   Further levels of N1, N2, are permitted as for FINDFIELD.
%
%   Notes
%   -----
%   This is not guaranteed to work with all Matlab structures and types.
%   Wildcards are not supported.
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
X = findfield(S, varargin{:});
Y = {};
if(~isempty(X))
    for i = 1:numel(X)
        S = X(i);
        
        if(iscell(S))
            S = S{1};
        end
        
        for j=1:numel(S)
            if(findfieldattr_match(S(j), AN, AV))
                Y = [ Y S(j) ] ; %#ok<AGROW>
            end
        end
    end
end


if(iscell(Y))
    Y = cell2mat(Y);
end
end


function B = findfieldattr_match(S, AN, AV)
B = (isfield(S, 'ATTRIBUTE') && isfield(S.ATTRIBUTE, AN) ...
    && isequal(S.ATTRIBUTE.(AN), AV));
end

function str = struct2flatstr(S)
%STRUCT2STR Recursively flattens a structure into a string representation
%   STR = STRUCT2STR(S) returns STR, a string representation of S
%   created by recursively taking the value of each field of S and
%   appending it to a string.
%
%   Notes
%   -----
%   This is not guaranteed to work with all Matlab structures and types.
%
%   Written by Gregory Scott (gregory.scott99@imperial.ac.uk)
%
if(ischar(S))
    str = S;
elseif(iscell(S))
    str = [];
    for x = 1:length(S)
        str = [ str struct2flatstr(S{x}) ]; %#ok<*AGROW>
    end
elseif(isstruct(S))
    names = fieldnames(S(1));
    
    for z = 1:length(S)
        str = [];
        for x = 1:length(names)
            str = [ str struct2flatstr(S(z).(names{x})) ];
        end
    end
else
    str = '';
end

end

function eventCheckList = defineEventCheckList()
%%
%DEFINEEVENTCHECKLIST
%
%   Notes
%   -----
%

eventCheckList = cell(1, 74);
eventCheckList{1} = cell(1, 2);
eventCheckList{1}{1} = 'Nonepileptic';
eventCheckList{1}{2} = 'Non-epileptic';
eventCheckList{2} = cell(1, 2);
eventCheckList{2}{1} = 'LeftarmsomatosensoryAura';
eventCheckList{2}{2} = 'Left arm somatosensory aura';
eventCheckList{3} = cell(1, 2);
eventCheckList{3}{1} = 'LeftlegsomatosensoryAura';
eventCheckList{3}{2} = 'Left leg somatosensory aura';
eventCheckList{4} = cell(1, 2);
eventCheckList{4}{1} = 'LeftarmlegsomatosensoryAura';
eventCheckList{4}{2} = 'Left arm + leg somatosensory aura';
eventCheckList{5} = cell(1, 2);
eventCheckList{5}{1} = 'RightarmsomatosensoryAura';
eventCheckList{5}{2} = 'Right arm somatosensory aura';
eventCheckList{6} = cell(1, 2);
eventCheckList{6}{1} = 'RightlegsomatosensoryAura';
eventCheckList{6}{2} = 'Right leg somatosensory aura';
eventCheckList{7} = cell(1, 2);
eventCheckList{7}{1} = 'RightarmlegsomatosensoryAura';
eventCheckList{7}{2} = 'Right arm + leg somatosensory aura';
eventCheckList{8} = cell(1, 2);
eventCheckList{8}{1} = 'BilateralsomatosensoryAura';
eventCheckList{8}{2} = 'Bilateral somatosensory aura';
eventCheckList{9} = cell(1, 2);
eventCheckList{9}{1} = 'LeftvisualAura';
eventCheckList{9}{2} = 'Left visual aura';
eventCheckList{10} = cell(1, 2);
eventCheckList{10}{1} = 'RightvisualAura';
eventCheckList{10}{2} = 'Right visual aura';
eventCheckList{11} = cell(1, 2);
eventCheckList{11}{1} = 'BilateralvisualAura';
eventCheckList{11}{2} = 'Bilateral visual aura';
eventCheckList{12} = cell(1, 2);
eventCheckList{12}{1} = 'LeftauditoryAura';
eventCheckList{12}{2} = 'Left auditory aura';
eventCheckList{13} = cell(1, 2);
eventCheckList{13}{1} = 'RightauditoryAura';
eventCheckList{13}{2} = 'Right auditory aura';
eventCheckList{14} = cell(1, 2);
eventCheckList{14}{1} = 'BilateralauditoryAura';
eventCheckList{14}{2} = 'Bilateral auditory aura';
eventCheckList{15} = cell(1, 2);
eventCheckList{15}{1} = 'AbdominalAura';
eventCheckList{15}{2} = 'Abdominal aura';
eventCheckList{16} = cell(1, 2);
eventCheckList{16}{1} = 'OlfactoryAura';
eventCheckList{16}{2} = 'Olfactory aura';
eventCheckList{17} = cell(1, 2);
eventCheckList{17}{1} = 'GustatoryAura';
eventCheckList{17}{2} = 'Gustatory aura';
eventCheckList{18} = cell(1, 3);
eventCheckList{18}{1} = 'PsychicAura';
eventCheckList{18}{2} = 'Psychic aura';
eventCheckList{18}{3} = 'Psychic';
% eventCheckList{18}{4} = 'psychic';
eventCheckList{19} = cell(1, 2);
eventCheckList{19}{1} = 'AutonomicAura';
eventCheckList{19}{2} = 'Autonomic aura';
eventCheckList{20} = cell(1, 2);
eventCheckList{20}{1} = 'UnspecifiedAura';
eventCheckList{20}{2} = 'Unspecified aura';
eventCheckList{21} = cell(1, 2);
eventCheckList{21}{1} = 'DialepticSeizure';
eventCheckList{21}{2} = 'Dialeptic seizure';
eventCheckList{22} = cell(1, 2);
eventCheckList{22}{1} = 'LeftarmmyoclonicSeizure';
eventCheckList{22}{2} = 'Left arm myoclonic seizure';
eventCheckList{23} = cell(1, 2);
eventCheckList{23}{1} = 'LeftlegmyoclonicSeizure';
eventCheckList{23}{2} = 'Left leg myoclonic seizure';
eventCheckList{24} = cell(1, 2);
eventCheckList{24}{1} = 'LeftarmlegmyoclonicSeizure';
eventCheckList{24}{2} = 'Left arm + leg myoclonic seizure';
eventCheckList{25} = cell(1, 2);
eventCheckList{25}{1} = 'RightarmmyoclonicSeizure';
eventCheckList{25}{2} = 'Right arm myoclonic seizure';
eventCheckList{26} = cell(1, 2);
eventCheckList{26}{1} = 'RightlegmyoclonicSeizure';
eventCheckList{26}{2} = 'Right leg myoclonic seizure';
eventCheckList{27} = cell(1, 2);
eventCheckList{27}{1} = 'RightarmlegmyoclonicSeizure';
eventCheckList{27}{2} = 'Right arm + leg myoclonic seizure';
eventCheckList{28} = cell(1, 2);
eventCheckList{28}{1} = 'AxialmyoclonicSeizure';
eventCheckList{28}{2} = 'Axial myoclonic seizure';
eventCheckList{29} = cell(1, 2);
eventCheckList{29}{1} = 'GeneralisedmyoclonicSeizure';
eventCheckList{29}{2} = 'Generalised myoclonic seizure';
eventCheckList{30} = cell(1, 2);
eventCheckList{30}{1} = 'AsymmetricmyoclonicSeizure';
eventCheckList{30}{2} = 'Asymmetric myoclonic seizure';
eventCheckList{31} = cell(1, 2);
eventCheckList{31}{1} = 'LeftarmtonicSeizure';
eventCheckList{31}{2} = 'Left arm tonic seizure';
eventCheckList{32} = cell(1, 2);
eventCheckList{32}{1} = 'LeftlegtonicSeizure';
eventCheckList{32}{2} = 'Left leg tonic seizure';
eventCheckList{33} = cell(1, 2);
eventCheckList{33}{1} = 'LeftarmlegtonicSeizure';
eventCheckList{33}{2} = 'Left arm + leg tonic seizure';
eventCheckList{34} = cell(1, 2);
eventCheckList{34}{1} = 'RightarmtonicSeizure';
eventCheckList{34}{2} = 'Right arm tonic seizure';
eventCheckList{35} = cell(1, 2);
eventCheckList{35}{1} = 'RightlegtonicSeizure';
eventCheckList{35}{2} = 'Right leg tonic seizure';
eventCheckList{36} = cell(1, 2);
eventCheckList{36}{1} = 'RightarmlegtonicSeizure';
eventCheckList{36}{2} = 'Right arm + leg tonic seizure';
eventCheckList{37} = cell(1, 2);
eventCheckList{37}{1} = 'AxialtonicSeizure';
eventCheckList{37}{2} = 'Axial tonic seizure';
eventCheckList{38} = cell(1, 2);
eventCheckList{38}{1} = 'GeneralisedtonicSeizure';
eventCheckList{38}{2} = 'Generalised tonic seizure';
eventCheckList{39} = cell(1, 2);
eventCheckList{39}{1} = 'AsymmetrictonicSeizure';
eventCheckList{39}{2} = 'Asymmetric tonic seizure';
eventCheckList{40} = cell(1, 2);
eventCheckList{40}{1} = 'LeftarmclonicSeizure';
eventCheckList{40}{2} = 'Left arm clonic seizure';
eventCheckList{41} = cell(1, 2);
eventCheckList{41}{1} = 'LeftlegclonicSeizure';
eventCheckList{41}{2} = 'Left leg clonic seizure';
eventCheckList{42} = cell(1, 2);
eventCheckList{42}{1} = 'LeftarmlegclonicSeizure';
eventCheckList{42}{2} = 'Left arm + leg clonic seizure';
eventCheckList{43} = cell(1, 2);
eventCheckList{43}{1} = 'RightarmclonicSeizure';
eventCheckList{43}{2} = 'Right arm clonic seizure';
eventCheckList{44} = cell(1, 2);
eventCheckList{44}{1} = 'RightlegclonicSeizure';
eventCheckList{44}{2} = 'Right leg clonic seizure';
eventCheckList{45} = cell(1, 2);
eventCheckList{45}{1} = 'RightarmlegclonicSeizure';
eventCheckList{45}{2} = 'Right arm + leg clonic seizure';
eventCheckList{46} = cell(1, 2);
eventCheckList{46}{1} = 'AxialclonicSeizure';
eventCheckList{46}{2} = 'Axial clonic seizure';
eventCheckList{47} = cell(1, 2);
eventCheckList{47}{1} = 'GeneralisedclonicSeizure';
eventCheckList{47}{2} = 'Generalised clonic seizure';
eventCheckList{48} = cell(1, 2);
eventCheckList{48}{1} = 'AsymmetricclonicSeizure';
eventCheckList{48}{2} = 'Asymmetric clonic seizure';
eventCheckList{49} = cell(1, 2);
eventCheckList{49}{1} = 'LeftarmtonicclonicSeizure';
eventCheckList{49}{2} = 'Left arm tonic/clonic seizure';
eventCheckList{50} = cell(1, 2);
eventCheckList{50}{1} = 'LeftlegtonicclonicSeizure';
eventCheckList{50}{2} = 'Left leg tonic/clonic seizure';
eventCheckList{51} = cell(1, 2);
eventCheckList{51}{1} = 'LeftarmlegtonicclonicSeizure';
eventCheckList{51}{2} = 'Left arm leg tonic/clonic seizure';
eventCheckList{52} = cell(1, 2);
eventCheckList{52}{1} = 'RightarmtonicclonicSeizure';
eventCheckList{52}{2} = 'Right arm tonic/clonic seizure';
eventCheckList{53} = cell(1, 2);
eventCheckList{53}{1} = 'RightlegtonicclonicSeizure';
eventCheckList{53}{2} = 'Right leg tonic/clonic seizure';
eventCheckList{54} = cell(1, 2);
eventCheckList{54}{1} = 'RightarmlegtonicclonicSeizure';
eventCheckList{54}{2} = 'Right arm + leg tonic/clonic seizure';
eventCheckList{55} = cell(1, 2);
eventCheckList{55}{1} = 'AxialtonicclonicSeizure';
eventCheckList{55}{2} = 'Axial tonic/clonic seizure';
eventCheckList{56} = cell(1, 2);
eventCheckList{56}{1} = 'GeneralisedtonicclonicSeizure';
eventCheckList{56}{2} = 'Generalised tonic/clonic seizure';
eventCheckList{57} = cell(1, 2);
eventCheckList{57}{1} = 'AsymmetrictonicclonicSeizure';
eventCheckList{57}{2} = 'Asymmetric tonic/clonic seizure';
eventCheckList{58} = cell(1, 2);
eventCheckList{58}{1} = 'LeftversiveSeizure';
eventCheckList{58}{2} = 'Left versive seizure';
eventCheckList{59} = cell(1, 2);
eventCheckList{59}{1} = 'RightversiveSeizure';
eventCheckList{59}{2} = 'Right versive seizure';
eventCheckList{60} = cell(1, 2);
eventCheckList{60}{1} = 'UnspecifiedsimplemotorSeizure';
eventCheckList{60}{2} = 'Unspecified simple motor seizure';
eventCheckList{61} = cell(1, 2);
eventCheckList{61}{1} = 'AutomotorSeizure';
eventCheckList{61}{2} = 'Automotor seizure';
eventCheckList{62} = cell(1, 2);
eventCheckList{62}{1} = 'HyperkineticSeizure';
eventCheckList{62}{2} = 'Hyperkinetic seizure';
eventCheckList{63} = cell(1, 2);
eventCheckList{63}{1} = 'UnspecifiedcomplexmotorSeizure';
eventCheckList{63}{2} = 'Unspecified complex motor seizure';
eventCheckList{64} = cell(1, 2);
eventCheckList{64}{1} = 'AtonicSeizure';
eventCheckList{64}{2} = 'Atonic seizure';
eventCheckList{65} = cell(1, 2);
eventCheckList{65}{1} = 'AstaticSeizure';
eventCheckList{65}{2} = 'Astatic seizure';
eventCheckList{66} = cell(1, 2);
eventCheckList{66}{1} = 'AphasicSeizure';
eventCheckList{66}{2} = 'Aphasic seizure';
eventCheckList{67} = cell(1, 2);
eventCheckList{67}{1} = 'NegativemyoclonicSeizure';
eventCheckList{67}{2} = 'Negative myoclonic seizure';
eventCheckList{68} = cell(1, 2);
eventCheckList{68}{1} = 'HypomotorSeizure';
eventCheckList{68}{2} = 'Hypomotor seizure';
eventCheckList{69} = cell(1, 2);
eventCheckList{69}{1} = 'GelasticSeizure';
eventCheckList{69}{2} = 'Gelastic seizure';
eventCheckList{70} = cell(1, 2);
eventCheckList{70}{1} = 'AutomotorWithLOA';
eventCheckList{70}{2} = 'automotor with loss of awareness';
eventCheckList{71} = cell(1, 2);
eventCheckList{71}{1} = 'ComplexMotorSeizure';
eventCheckList{71}{2} = 'Complex motor';
eventCheckList{72} = cell(1, 2);
eventCheckList{72}{1} = 'Psychic';
eventCheckList{72}{2} = 'psychic';
eventCheckList{73} = cell(1, 2);
eventCheckList{73}{1} = 'Autonomic';
eventCheckList{73}{2} = 'autonomic';
eventCheckList{74} = cell(1, 2);
eventCheckList{74}{1} = 'AsAbove';
eventCheckList{74}{2} = 'as above';

end


% -------------------------------------------------------------------------
function [LAT P] = guesslanguagelateralisation(str)
%%
%GUESSLATERALISATION Guess the language lateralisation from a string
%
%   Notes
%   -----
%
lats = { 'Left', 'Right', 'Bilateral' };

nleft = length(regexpi((str), '\<(left|left hemisphere|left hemispheric)\>'));
nright = length(regexpi((str), '\<(right|right hemisphere|right hemispheric)\>'));
nbilat = length(regexpi((str), '\<(bilateral|bi-hemispheric|bihemispheric|both)\>'));

ntotal = nleft + nright + nbilat;

ps = [ nleft / ntotal, nright / ntotal, nbilat / ntotal ];

P = max(ps);

if(isnan(P))
    LAT = 'Unknown';
else
    LAT = lats{find(ps == max(ps))}; %#ok<FNDSB>
end
end

