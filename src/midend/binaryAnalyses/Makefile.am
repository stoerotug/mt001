include $(top_srcdir)/config/Makefile.for.ROSE.includes.and.libs

INCLUDES = -Winvalid-pch $(ROSE_INCLUDES) -I$(srcdir)/graph -I$(srcdir)/libraryIdentification 

noinst_LTLIBRARIES = libbinaryMidend.la
libbinaryMidend_la_DEPENDENCIES =

if ROSE_BUILD_BINARY_ANALYSIS_SUPPORT
libbinaryMidend_la_SOURCES = \
     binary_analysis.C \
     RoseBin_CompareAnalysis.cpp RoseBin_ControlFlowAnalysis.cpp \
     RoseBin_printInstructions.cpp RoseBin_DataFlowAnalysis.cpp \
     RoseBin_CallGraphAnalysis.cpp RoseBin_FlowAnalysis.cpp \
     dataflowanalyses/RoseBin_DefUseAnalysis.cpp \
     dataflowanalyses/RoseBin_VariableAnalysis.cpp \
     dataflowanalyses/InterruptAnalysis.cpp \
     dataflowanalyses/RoseBin_Emulate.cpp \
     dataflowanalyses/RoseBin_DataFlowAbstract.cpp \
     instructionSemantics/findConstants.C \
     instructionSemantics/FindRegisterDefs.C \
     instructionSemantics/InsnSemanticsExpr.C \
     instructionSemantics/IntervalSemantics.C \
     instructionSemantics/PartialSymbolicSemantics.C \
     instructionSemantics/SMTSolver.C \
     instructionSemantics/SymbolicSemantics.C \
     instructionSemantics/YicesSolver.C \
     GraphAlgorithms.C \
     BinaryControlFlow.C \
     BinaryDominance.C \
     BinaryFunctionCall.C \
     BinaryCallingConvention.C
else
libbinaryMidend_la_SOURCES = dummyBinaryMidend.C
endif

if ROSE_USE_SQLITE_DATABASE
libbinaryMidend_la_SOURCES += \
     libraryIdentification/libraryIdentification_reader.C \
     libraryIdentification/libraryIdentification_writer.C \
     libraryIdentification/functionIdentification.C 
endif

include_HEADERS = \
   binary_analysis.h \
   GraphAlgorithms.h \
   RoseBin_CallGraphAnalysis.h \
   RoseBin_CompareAnalysis.h \
   RoseBin_ControlFlowAnalysis.h \
   RoseBin_DataFlowAnalysis.h \
   RoseBin_FlowAnalysis.h \
   RoseBin_printInstructions.h \
   dataflowanalyses/InterruptAnalysis.h \
   dataflowanalyses/RoseBin_DataFlowAbstract.h \
   dataflowanalyses/RoseBin_DefUseAnalysis.h \
   dataflowanalyses/RoseBin_Emulate.h \
   dataflowanalyses/RoseBin_VariableAnalysis.h \
   instructionSemantics/ReadWriteRegisterFragment.h \
   instructionSemantics/findConstants.h \
   instructionSemantics/FindRegisterDefs.h \
   instructionSemantics/InsnSemanticsExpr.h \
   instructionSemantics/BaseSemantics.h \
   instructionSemantics/IntervalSemantics.h \
   instructionSemantics/NullSemantics.h \
   instructionSemantics/MultiSemantics.h \
   instructionSemantics/PartialSymbolicSemantics.h \
   instructionSemantics/SMTSolver.h \
   instructionSemantics/SymbolicSemantics.h \
   instructionSemantics/YicesSolver.h \
   instructionSemantics/flowEquations.h \
   instructionSemantics/semanticsModule.h \
   instructionSemantics/x86InstructionSemantics.h \
   libraryIdentification/functionIdentification.h \
   libraryIdentification/libraryIdentification.h \
   ether.h \
   BinaryControlFlow.h \
   BinaryDominance.h \
   BinaryFunctionCall.h \
   BinaryCallingConvention.h


EXTRA_DIST = CMakeLists.txt dummyBinaryMidend.C
