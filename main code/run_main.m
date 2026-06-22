% main нд╪Ч
clc
clear
close all
currPath = fileparts(mfilename('fullpath'));% get current path
p = cd(currPath);  %open the m file folder
addpath(genpath( './main code'));
warning('off');
SIM_main_ui; 