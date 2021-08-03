#!/bin/bash

zip -9r lowrezjam2021.`date +%Y%m%d%H%M`.love . -x*.swp -xage-project/* -xconcept/* -x.git* -x*.love
