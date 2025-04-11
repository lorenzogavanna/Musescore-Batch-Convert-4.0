import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FileIO
import QtQml

import Muse.UiComponents
import Muse.Ui
import MuseScore

MuseScore {
    version: "1.0"
    id: root
    pluginType: "dialog"
    requiresScore: false
    width: 600
    height: 750
	
	property var pluginName: "Batch Convert 4.0"
	property int isTest: 0 //show test btns if 1 you will be able to show test btns
	property int justPreview: 0 //0 will perform the conversion 1 will not
	//check onCompleted for value
	property string pgFldr: ""		//plugin Folder
	property string appEx: ""		//Musescore executable address
    property string currOs: ""		//current Os
	property var splFlLst: []
	property var exportExtension:"pdf"
	property var exportType:1 //1 only score, 2 only parts, 3 all score and parts
	property var isRunning:""
	
	Component.onCompleted : {

		title = "Batch Convert 4.0";
		thumbnailName = "batch_convert_thumbnail.png";
		categoryCode = "Batch process";

		pgFldr = String(Qt.resolvedUrl(".")).replace("file:///", "").replace(/\//g, "\\");
		appEx = Qt.application.arguments[0];
		currOs = Qt.platform.os;
    }
	
	SelectMultipleDirectoriesModel {
		id: directoriesModelImport
	}
	
	SelectMultipleDirectoriesModel {
		id: directoriesModelExport
	}
	
	Connections {
		target: directoriesModelImport
		onDirectoryAdded: {
			let importDir=directoriesModelImport.directories();
			logWr("New import directory! " + importDir);
			txtImport.text=importDir
		}
	}
	
	Connections {
		target: directoriesModelExport
		onDirectoryAdded: {
			let exportDir=directoriesModelExport.directories();
			logWr("New export directory! " + exportDir);
			txtExport.text=exportDir
		}
	}

	Rectangle {
		id: customAlert
		visible: false
		anchors.centerIn: parent
		width: 200
		height: 100
		color: "#FF9999"
		border.color: "black"
		radius: 10
		z: 999

		property string message: "Error!"

		Column {
			anchors.centerIn: parent
			spacing: 10
			width: parent.width
			anchors.margins: 10

			Text {
				text: customAlert.message
				color: "red"
				wrapMode: Text.Wrap
				horizontalAlignment: Text.AlignHCenter
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width
			}

			Rectangle {
				width: 60
				height: 30
				color: "#FFCCCC"
				border.color: "black"
				radius: 5
				anchors.horizontalCenter: parent.horizontalCenter

				Text {
					anchors.centerIn: parent
					text: "OK"
					color: "black"
				}

				MouseArea {
					anchors.fill: parent
					onClicked: customAlert.visible = false
				}
			}
		}
	}


	FileIO {
		id: batFile
		source: pgFldr + "temp/convert.bat";
	}
	
	FileIO {
		id: listBatFile
		source: pgFldr + "temp/list.bat";
	}
	
	FileIO {
		id: listFile
		source: pgFldr + "temp/list.txt";		
	}
	
	FileIO {
		id: jsonFile
		source: pgFldr + "temp/job.json";		
	}
	

    Rectangle {
        id: base
        width: parent.width
        height: 350
        color: "#2d2d30"
		
		Column {
			id: mainColumn
			spacing: 10
			anchors.fill: parent
			anchors.margins: 10

			Row {
				id: importRow
				spacing: 5

				Text {
					id: impTxt
					text: "Import folder"
					font.pixelSize: 12
					color: "white"
					width: 80
					height: 30
					verticalAlignment: Text.AlignVCenter
				}

				Rectangle {
					id: importFldBg
					width: 445
					height: 30
					border.color: "black"
					border.width: 1
					color: "#d5d5d5"

					TextArea {
						id: txtImport
						width: parent.width
						height: parent.height
						color: "black"
					}
				}

				CustomButton {
					id: btnImport
					text: "Browse"
					height: importFldBg.height
					onClicked: {
						directoriesModelImport.load("", "")
						directoriesModelImport.addDirectory()
					}
				}
			}

			Row {
				id: exportRow
				spacing: 5

				Text {
					id: expTxt
					text: "Export folder"
					font.pixelSize: 12
					color: "white"
					width: 80
					height: 30
					verticalAlignment: Text.AlignVCenter
				}

				Rectangle {
					id: exportFldBg
					width: 445
					height: 30
					border.color: "black"
					border.width: 1
					color: "#d5d5d5"

					TextArea {
						id: txtExport
						width: parent.width
						height: parent.height
						color: "black"
					}
				}

				CustomButton {
					id: btnExport
					text: "Browse"
					height: exportFldBg.height
					onClicked: {
						directoriesModelExport.load("", "")
						directoriesModelExport.addDirectory()
					}
				}
			}
			Row {
				id: filterRow
				spacing: 5

				Text {
					id: fltTxt
					text: "Filter file with"
					font.pixelSize: 12
					color: "white"
					width: 80
					height: 30
					verticalAlignment: Text.AlignVCenter
				}

				Rectangle {
					id: filterFldBg
					width: 445
					height: 30
					border.color: "black"
					border.width: 1
					color: "#d5d5d5"

					TextArea {
						id: txtFilter
						width: parent.width
						height: parent.height
						color: "black"
						ToolTip.visible: txtFilter.hovered
						ToolTip.text: "Default is no filter.\nEnter a wildcard pattern for filtering:\n* = any characters\n? = any single character\ni.e.:\n  *clarinet* → files containing 'clarinet'\n  ??score → files like '01score'"
					}
				}
			}

			Rectangle {
				id: formatSelector
				width: parent.width
				height: outputFormatFlow.implicitHeight + 20
				color: "transparent"
				border.width:1
				border.color:"#b7b7b7"

				Flow {
					id: outputFormatFlow
					anchors.left: parent.left
					anchors.leftMargin: 10
					anchors.top: parent.top
					anchors.topMargin: 10
					spacing: 10
					width: parent.width - 20

					Text {
						id: outputTitle
						text: "Output format"
						font.pixelSize: 12
						color: "white"
						height: 30
						verticalAlignment: Text.AlignVCenter
					}

					RdBtn { id: mscz; text: "mscz"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: mscx; text: "mscx"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: musicxml; text: "musicxml"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: mxl; text: "mxl"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: mid; text: "mid"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: midi; text: "midi"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: pdf; text: "pdf"; checked: true; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: png; text: "png"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: svg; text: "svg"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: wav; text: "wav"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: flac; text: "flac"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: ogg; text: "ogg"; onCheckedChanged: exportExtension = checked ? text : "" }
					RdBtn { id: mp3; text: "mp3"; onCheckedChanged: exportExtension = checked ? text : "" }
				}
			}
			
		Rectangle {
				id: exportSelector
				width: parent.width
				height: exportSelectorFlow.implicitHeight + 20
				color: "transparent"
				border.width:1
				border.color:"#b7b7b7"

				Flow {
					id: exportSelectorFlow
					anchors.left: parent.left
					anchors.leftMargin: 10
					anchors.top: parent.top
					anchors.topMargin: 10
					spacing: 50
					width: parent.width - 20

					Text {
						id: exportTypeTitle
						text: "Export:"
						font.pixelSize: 12
						color: "white"
						height: 30
						verticalAlignment: Text.AlignVCenter
					}
					RdBtn { id: score; text: "Score"; checked: true; onCheckedChanged: exportType = checked ? 1 : "" }
					RdBtn { id: all; text: "Score and parts"; onCheckedChanged: exportType = checked ? 3 : "" }
					RdBtn { id: parts; text: "Parts only"; onCheckedChanged: exportType = checked ? 2 : "" }
				}
			}			
			
			
		}

			
		Row { //last buttons row
			anchors.bottom: base.bottom
			spacing: 10
			anchors.left: parent.left
			anchors.leftMargin: 10  

			CustomButton {
				text: "Convert"
				height: 30
				width: 60
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 10

				onClicked: {
					readFldrAndConvert(0);
				}
			}
			
			CustomButton {
				text: "Preview"
				height: 30
				width: 60
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 10

				onClicked: {
					readFldrAndConvert(1);
				}
			}

			CustomButton {
				text: "Close"
				height: 30
				width: 60
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 10

				onClicked: {
					quit();
				}
			}
			CustomButton { 
				text: "Reset Log"
				height: 30
				width: 60
				visible: isTest === 1
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 10
				onClicked: {
					_ltxt("");
				}
			}

			CustomButton {
				text: "Test"
				height: 30
				width: 60
				visible: isTest === 1
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 10

				onClicked: {
					test();
				}
			}

			CustomButton {
				text: "Log"
				height: 30
				width: 60
				visible: isTest === 1
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 10

				onClicked: {					
					_ltxt(exportType.toString());	
					_l();	
				}
			}
			
			CkBx {
				id: myCheckBox
				text: "Only test do not convert"
				visible: isTest === 1
				onClicked: {
					_ltxt("Checked: ", myCheckBox.checked ? "Yes" : "No")
				}
			}
		}
		
		Rectangle {
			anchors.top: base.bottom
			width: parent.width
			anchors.left: parent.left
			height: 400
			color:"#d5d5d5"		
			border.color: "#2d2d30"
			border.width: 5         
			
			ScrollView {
			width: parent.width
			height: parent.height
				TextArea {
					id: lblLog
					color: "blue"
					wrapMode: TextArea.Wrap
					readOnly: true
				}
			}
		}

	}//rec

    //functions
	
	function test(str){

			_ltxt(isValidPath(txtImport.text).toString(),currOs);
	}

	function _l(str1,str2,str3,str4){
		let strings = [str1, str2, str3, str4];
		let validStrings = strings.filter(str => str && str.trim() !== "");		
		logWr("\n" + validStrings.join("\n"));
	}
	
	function _ltxt(str1, str2, str3, str4) {
		let strings = [str1, str2, str3, str4];
		let validStrings = strings.filter(str => str && str.trim() !== "");
		lblLog.text = validStrings.join("\n");
	}

	function readFldrAndConvert(isPreview) {
		if (txtImport.text === "") {
			customAlert.visible = true;
			customAlert.message = "Please set an import directory";
		} else if (!isValidPath(txtImport.text)) {
			customAlert.visible = true;
			customAlert.message = "Invalid import path format";
		} else if (txtExport.text === "") {
			customAlert.visible = true;
			customAlert.message = "Please set an export directory";
		} else if (!isValidPath(txtExport.text)) {
			customAlert.visible = true;
			customAlert.message = "Invalid export path format";
		} else {
			justPreview=isPreview;
			if (!txtImport.text.endsWith("/")) txtImport.text += "/";
			if (!txtExport.text.endsWith("/")) txtExport.text += "/";
			_ltxt("Reading folder " + txtImport.text);
			
			var fileExtension = "*.mscz";

			var fldrPath = pgFldr.replace(/\\/g, "/");
			if (!fldrPath.endsWith("/")) {
				fldrPath += "/";
			}

			var importPath = txtImport.text.replace(/\//g, "\\");
			if (!importPath.endsWith("\\")) {
				importPath += "\\";
			}

			var fullImportPathWithFilter = importPath + txtFilter.text + fileExtension;
			var escapedImportPath = escapePath(fullImportPathWithFilter);

			var listPathRaw = listFile.source;
			var listPathWin = listPathRaw.replace(/\//g, "\\");
			_l(listPathWin);

			var escapedListPath = escapePath(listPathWin);

			var listCmd = `dir /b /o:n ${escapedImportPath} > ${escapedListPath}`;

			_l(listCmd);
			listBatFile.write(listCmd);

			var listBatUrl = "file:///" + listBatFile.source.replace(/\\/g, "/");
			Qt.openUrlExternally(listBatUrl);
			timer.interval = 3000; 
			timer.repeat = false; 
			timer.start();	
		}
	}
	
	function isValidPath(path) {
		if (path === "")
			return false;

		if (currOs === "windows") {
			var winPattern = /^[a-zA-Z]:[\\/](?:[^<>:"|?*]+[\\/]?)*$/;
			return winPattern.test(path);
		} else {
			var unixPattern = /^(\/[^\/\0<>:"|?*]+)*\/?$/;
			return unixPattern.test(path);
		}
	}
	
	function escapePath(path) {
		
		return `"${path}"`;
	}

	Timer{
		id:timer
		onTriggered:{
			convert();
		}
	}

	function convert() {// read and convert after timer

		var flLst = listFile.read();
		splFlLst = flLst.split("\n").filter(item => item.trim() !== "");

		if (splFlLst.length === 0) {
			customAlert.visible = true;
			customAlert.message = "The import folder is empty or no files match your filter.";
			_ltxt(lblLog.text,"The import folder is empty or no files match your filter.")
			return;
		}
		var expTp = "";
		if (exportType === 1) {
			expTp = "Score";
		} else if (exportType === 2) {
			expTp = "Parts";
		} else if (exportType === 3) {
			expTp = "Score and parts";
		}
		
		_ltxt(lblLog.text,"Will convert " + expTp + " for file(s): ",splFlLst.toString().split(",").join("\n"));
		
		if (justPreview === 1) return;

		
		var jsonArray = [];
		var inputFiles = [];
		var outputFiles = [];
		var outputFilesParts = [];
		
		for (var i = 0; i < splFlLst.length; i++) {
			var fileName = splFlLst[i].trim();
			if (fileName === "" || !fileName.endsWith(".mscz")) continue;

			inputFiles[i] = txtImport.text + fileName;

			var baseName = fileName.slice(0, -".mscz".length);

			outputFiles[i] = txtExport.text + baseName;
			outputFilesParts[i] = txtExport.text + baseName + "_";

			const outArray = [];

			if (exportType === 1 || exportType === 3) {
				outArray.push(`${outputFiles[i]}.${exportExtension}`);
			}

			if (exportType === 2 || exportType === 3) {
				outArray.push([outputFilesParts[i], `.${exportExtension}`]);
			}

			jsonArray.push({
				"in": inputFiles[i],
				"out": outArray
			});

		}
		
		var jsonStr = JSON.stringify(jsonArray, null, 2);

		var jobPath = jsonFile.source.replace(/\\/g, "/");
		var jobStr = `@echo off\r\n echo Converting, wait...\r\n"${appEx}" mscore -j "${jobPath.replace(/\//g, "\\")}"`;

		jsonFile.write(jsonStr);
		batFile.write(jobStr);

		var batUrl = "file:///" + batFile.source.replace(/\\/g, "/");
		Qt.openUrlExternally(batUrl);
		isPreview=0;
	}
	// DEBUG TOOL //
	property string logContent: ""
	FileIO {
		id: logFile
		source: pgFldr + "/log/" + pluginName + "_log.txt";
	}
	 
	function logWr(str) {
		logContent = getDate() + " " + str + "\n" + logContent;
		writeLogFile();
	}
    function writeLogFile(clearLog = false) {
        logFile.write(logContent);
        if (clearLog)
            logContent = "";
    }	
	function getDate() {
		var now = Qt.formatDateTime(new Date(), "yyyy-MM-dd h:mm:ss AP");
		return now;
	}
	// END DEBUG TOOL //
}//muse