# ***Mia***: Mobile influenza analysis
This repository was created for use by CDC programs to collaborate on public health surveillance related projects in support of the CDC Surveillance Strategy.  Github is not hosted by the CDC, but is used by CDC and its partners to share information and collaborate on software.

This repository contains scripts used for the manuscript *Mitigating Pandemic Risk with Influenza Virus A Field Survillance at a Swine-Human Interface* currently available at [BioRxiv](https://www.biorxiv.org/content/10.1101/585588v1) and in submission for peer-review publication. This is currently a beta version and requires substantial dependencies. A containerized version is under active development and when available, a redirect will be available here.

## Installation
```bash
git clone https://github.com/CDCgov/Mia_publication.git
cd MIA/scripts
sudo bash install.sh
cd -
```

## Dependencies
Everything below is attempted to install with ./MIA/scripts/install.sh.
Due to the large number of dependencies however, there is a decent chance everything will not 
properly install, requiring some manual troubleshooting/install. Setting up the R environment
can be particularly sticky.

#### [Python 3.5 and 2.7](https://www.python.org/downloads/release/python-357/)
```bash
sudo apt-get install python3.5
sudo apt-get install python2.7
```

#### [MinKnow](https://community.nanoporetech.com/protocols/experiment-companion-minknow/v/mke_1013_v1_revao_11apr2016/installing-minknow-on-linu)
```bash
sudo apt-get update
sudo apt-get install wget
wget -O- https://mirror.oxfordnanoportal.com/apt/ont-repo.pub | sudo apt-key add -
echo "deb http://mirror.oxfordnanoportal.com/apt xenial-stable non-free" | sudo tee /etc/apt/sources.list.d/nanoporetech.sources.list
sudo apt-get update
sudo apt-get install minknow-nc
```

#### [Guppy](https://community.nanoporetech.com/protocols/Guppy-protocol/v/gpb_2003_v1_revl_14dec2018/linux-guppy)
```bash
sudo apt-get update 
sudo apt-get install wget lsb-release 
export PLATFORM=$(lsb_release -cs) 
wget -O- https://mirror.oxfordnanoportal.com/apt/ont-repo.pub | sudo apt-key add - 
echo "deb http://mirror.oxfordnanoportal.com/apt ${PLATFORM}-stable non-free" | sudo tee /etc/apt/sources.list.d/nanoporetech.sources.list 
sudo apt-get update 
```

#### [Aliview](http://www.ormbunkar.se/aliview/downloads/linux/linux-version-1.26/)
```bash
cd bin
wget http://www.ormbunkar.se/aliview/downloads/linux/linux-version-1.26/aliview.install.run
chmod +x
sudo ./aliview.install.run
cd -
```

#### [inotifywait](https://packages.debian.org/source/jessie/inotify-tools)
```bash
sudo apt-get install inotify-tools
```

#### [IRMA: Iterative Refinement MetaAssembler](https://wonder.cdc.gov/amd/flu/irma/install.html)
IRMA is prepackaged within Mia's repository and should work without requiring the following install:
```bash
cd bin
wget https://wonder.cdc.gov/amd/flu/irma/flu-amd.zip
unzip flu-amd.zip
cd -
```

#### [BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download)
BLAST+ is prepackaged within Mia's repository and should work without requiring the following install:
```bash
cd lib
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.9.0+-x64-linux.tar.gz
tar -xzf ncbi-blast-2.9.0+-x64-linux.tar.gz
cd -
```

#### [FastTree Double Precision](http://www.microbesonline.org/fasttree/#Install)
```bash
cd bin 
wget http://www.microbesonline.org/fasttree/FastTreeDbl
cd -
```

#### [Muscle](http://www.drive5.com/muscle/)
Muscle is prepackaged within Mia's repository and should work without requiring the following install:
```bash
cd bin
wget http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
tar -xzf muscle3.8.31_i86linux64.tar.gz
cd -
```

#### [SQLite](https://www.sqlite.org/index.html)
[Install SQLite](#Build-database-and-initialize-references)

#### [R](https://mran.microsoft.com/open)
```bash
cd bin
wget https://mran.blob.core.windows.net/install/mro/3.5.3/ubuntu/microsoft-r-open-3.5.3.tar.gz
tar -xf microsoft-r-open-3.5.3.tar.gz
sudo microsoft-r-open/install.sh
# Follow prompts
cd -
```
##### R dependencies
```bash
sudo Rscript ./scripts/install_R_libs.R
```

## Build database and initialize references
```bash
cd scripts
bash createMIAdb.sh
cd -
```

## Create Desktop Icon
```bash
cd scripts
bash makeDesktopIcon.sh
cd -
```

## Set crontab
```bash
cd scripts
bash setCron.sh
cd -
```

  
## Public Domain
This repository constitutes a work of the United States Government and is not
subject to domestic copyright protection under 17 USC § 105. This repository is in
the public domain within the United States, and copyright and related rights in
the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication. By
submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## License
The repository utilizes code licensed under the terms of the Apache Software
License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under
the terms of the Apache Software License version 2, or (at your option) any
later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this
program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.


## Privacy
This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
Surveillance Platform [Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md)
and [Code of Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
For more information about CDC's privacy policy, please visit [http://www.cdc.gov/privacy.html](http://www.cdc.gov/privacy.html).

## Contributing
Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo)
and submitting a pull request. (If you are new to GitHub, you might start with a
[basic tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual, irrevocable,
non-exclusive, transferable license to all users under the terms of the
[Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or
later.

All comments, messages, pull requests, and other submissions received through
CDC including this GitHub page are subject to the [Presidential Records Act](http://www.archives.gov/about/laws/presidential-records.html)
and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

## Records
This repository is not a source of government records, but is a copy to increase
collaboration and collaborative potential. All government records will be
published through the [CDC web site](http://www.cdc.gov).

## Notices
Please refer to [CDC's Template Repository](https://github.com/CDCgov/template)
for more information about [contributing to this repository](https://github.com/CDCgov/template/blob/master/CONTRIBUTING.md),
[public domain notices and disclaimers](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md),
and [code of conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).

