#include "sage3basic.h"

#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif
#include <inttypes.h>

#include "AsmFunctionIndex.h"
#include "stringify.h"

#include <boost/shared_ptr.hpp>

void
AsmFunctionIndex::OutputCallback::set_prefix(const std::string &header, const std::string &separator, const std::string &data)
{
    header_prefix = header;
    separator_prefix = separator;
    data_prefix = data;
}

std::ostream&
operator<<(std::ostream &o, const AsmFunctionIndex &index)
{
    index.print(o);
    return o;
}

void
AsmFunctionIndex::init()
{
    output_callbacks
        .append(&rowIdCallback)
        .append(&entryAddrCallback)
        .append(&beginAddrCallback)
        .append(&endAddrCallback)
        .append(&sizeInsnsCallback)
        .append(&sizeBytesCallback)
        .append(&reasonCallback)
        .append(&callingConventionCallback)
        .append(&nameCallback)
        .append(&footnotesCallback)
        ;
}

void
AsmFunctionIndex::add_function(SgAsmFunction *func)
{
    if (func)
        functions.push_back(func);
}

void
AsmFunctionIndex::add_functions(SgNode *ast)
{
    struct T1: public AstSimpleProcessing {
        AsmFunctionIndex *index;
        T1(AsmFunctionIndex *index): index(index) {}
        void visit(SgNode *node) { index->add_function(isSgAsmFunction(node)); }
    };
    T1(this).traverse(ast, preorder);
}

void
AsmFunctionIndex::print(std::ostream &out) const
{
    Footnotes *footnotes = new Footnotes;
    footnotes->set_footnote_prefix("  ");
    boost::shared_ptr<Footnotes> __attribute__((unused)) exception_cleanup(footnotes);

    output_callbacks.apply(true, OutputCallback::BeforeAfterArgs(this, out, footnotes, 0/*before*/));

    output_callbacks.apply(true, OutputCallback::HeadingArgs(this, out, footnotes));
    out <<std::endl;
    output_callbacks.apply(true, OutputCallback::HeadingArgs(this, out, footnotes, '-'));
    out <<std::endl;

    for (size_t row_id=0; row_id<functions.size(); ++row_id) {
        output_callbacks.apply(true, OutputCallback::DataArgs(this, out, footnotes, functions[row_id], row_id));
        out <<std::endl;
    }

    output_callbacks.apply(true, OutputCallback::HeadingArgs(this, out, footnotes, '-'));
    out <<std::endl;

    output_callbacks.apply(true, OutputCallback::BeforeAfterArgs(this, out, footnotes, 1/*after*/));
}

size_t
AsmFunctionIndex::Footnotes::add_footnote(const std::string &text)
{
    assert(!footnotes.empty()); // element zero is the title above the footnotes
    footnotes.push_back(text);
    return footnotes.size()-1;
}

void
AsmFunctionIndex::Footnotes::change_footnote(size_t idx, const std::string &text)
{
    assert(idx>0 && idx<footnotes.size()); // footnotes[0] is the title above the footnotes
    footnotes[idx] = text;
}

const std::string &
AsmFunctionIndex::Footnotes::get_footnote(size_t idx) const
{
    assert(idx>0 && idx<footnotes.size()); // footnotes[0] is the title above the footnotes
    return footnotes[idx];
}

std::string
AsmFunctionIndex::Footnotes::get_footnote_name(size_t idx) const
{
    return "*" + StringUtility::numberToString(idx);
}

void
AsmFunctionIndex::Footnotes::set_footnote_title(const std::string &title)
{
    if (footnotes.empty()) {
        footnotes.push_back(title);
    } else {
        footnotes[0] = title;
    }
}

const std::string &
AsmFunctionIndex::Footnotes::get_footnote_title() const
{
    assert(!footnotes.empty());
    return footnotes[0];
}

void
AsmFunctionIndex::Footnotes::print(std::ostream &output) const
{
    bool title_printed = false;
    for (size_t i=1; i<size(); ++i) {
        if (!get_footnote(i).empty()) {
            if (!title_printed && !get_footnote_title().empty()) {
                output <<StringUtility::prefixLines(get_footnote_title(), get_footnote_prefix());
                if (!StringUtility::isLineTerminated(get_footnote_title()))
                    output <<"\n";
                title_printed = true;
            }

            std::string name = "Footnote " + get_footnote_name(i) + ": ";
            output <<get_footnote_prefix() <<name
                   <<StringUtility::prefixLines(get_footnote(i), get_footnote_prefix()+std::string(name.size(), ' '), false);
            if (!StringUtility::isLineTerminated(get_footnote(i)))
                output <<"\n";
        }
    }
}


std::string
AsmFunctionIndex::OutputCallback::center(const std::string &s, size_t width)
{
    if (s.size()>=width)
        return s;
    size_t rtsz = (width - s.size()) / 2;
    size_t ltsz = width - (s.size() + rtsz);
    return std::string(ltsz, ' ') + s + std::string(rtsz, ' ');
}

bool
AsmFunctionIndex::OutputCallback::operator()(bool enabled, const BeforeAfterArgs &args)
{
    return enabled;
}

bool
AsmFunctionIndex::OutputCallback::operator()(bool enabled, const HeadingArgs &args)
{
    if (enabled && width>0) {
        if (args.sep) {
            args.output <<separator_prefix <<std::string(width, args.sep);
        } else {
            std::string s = name;
            if (!desc.empty()) {
                size_t fnum = args.footnotes->add_footnote(desc);
                s += "(" + args.footnotes->get_footnote_name(fnum) + ")";
            }
            args.output <<header_prefix <<center(s, width);
        }
    }
    return enabled;
}

bool
AsmFunctionIndex::OutputCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled && width>0)
        args.output <<data_prefix <<std::setw(width) <<"";
    return enabled;
}

bool
AsmFunctionIndex::RowIdCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled)
        args.output <<data_prefix <<std::setw(width) <<args.rowid;
    return enabled;
}

bool
AsmFunctionIndex::EntryAddrCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled)
        args.output <<data_prefix <<std::setw(width) <<StringUtility::addrToString(args.func->get_entry_va());
    return enabled;
}

bool
AsmFunctionIndex::BeginAddrCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled) {
        std::vector<SgAsmInstruction*> insns = SageInterface::querySubTree<SgAsmInstruction>(args.func);
        if (!insns.empty()) {
            rose_addr_t addr = insns.front()->get_address();
            for (std::vector<SgAsmInstruction*>::iterator ii=insns.begin(); ii!=insns.end(); ++ii)
                addr = std::max(addr, (*ii)->get_address());
            args.output <<data_prefix <<std::setw(width) <<StringUtility::addrToString(addr);
        } else {
            args.output <<data_prefix <<std::setw(width) <<"";
        }
    }
    return enabled;
}

bool
AsmFunctionIndex::EndAddrCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled) {
        std::vector<SgAsmInstruction*> insns = SageInterface::querySubTree<SgAsmInstruction>(args.func);
        if (!insns.empty()) {
            rose_addr_t addr = insns.front()->get_address() + insns.front()->get_size();
            for (std::vector<SgAsmInstruction*>::iterator ii=insns.begin(); ii!=insns.end(); ++ii)
                addr = std::max(addr, (*ii)->get_address()+(*ii)->get_size());
            args.output <<data_prefix <<std::setw(width) <<StringUtility::addrToString(addr);
        } else {
            args.output <<data_prefix <<std::setw(width) <<"";
        }
    }
    return enabled;
}

bool
AsmFunctionIndex::SizeInsnsCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled) {
        std::vector<SgAsmInstruction*> insns = SageInterface::querySubTree<SgAsmInstruction>(args.func);
        args.output <<data_prefix <<std::setw(width) <<insns.size();
    }
    return enabled;
}
bool
AsmFunctionIndex::SizeBytesCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled) {
        std::vector<SgAsmInstruction*> insns = SageInterface::querySubTree<SgAsmInstruction>(args.func);
        size_t nbytes=0;
        for (std::vector<SgAsmInstruction*>::iterator ii=insns.begin(); ii!=insns.end(); ++ii)
            nbytes += (*ii)->get_size();
        std::ios_base::fmtflags oflags = args.output.flags();
        args.output <<data_prefix <<std::setw(width) <<std::left <<nbytes;
        args.output.flags(oflags);
    }
    return enabled;
}

bool
AsmFunctionIndex::ReasonCallback::operator()(bool enabled, const HeadingArgs &args)
{
    if (enabled) {
        size_t width = SgAsmFunction::reason_str(true, 0).size();
        if (args.sep) {
            args.output <<separator_prefix <<std::setw(width) <<std::string(width, args.sep);
        } else {
            size_t footnote = args.footnotes->add_footnote(SgAsmFunction::reason_key());
            args.output <<header_prefix <<center(name+"("+args.footnotes->get_footnote_name(footnote)+")", width);
        }
    }
    return enabled;
}

bool
AsmFunctionIndex::ReasonCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled) {
        std::string s = args.func->reason_str(true);
        args.output <<data_prefix <<s;
    }
    return enabled;
}

bool
AsmFunctionIndex::CallingConventionCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled)
        args.output <<data_prefix
                    <<std::setw(width) <<stringifySgAsmFunction_function_kind_enum(args.func->get_function_kind(), "e_");
    return enabled;
}

bool
AsmFunctionIndex::NameCallback::operator()(bool enabled, const DataArgs &args)
{
    if (enabled) {
        std::ios_base::fmtflags oflags = args.output.flags();
        args.output <<data_prefix <<std::left <<std::setw(width) <<args.func->get_name();
        args.output.flags(oflags);
    }
    return enabled;
}

bool
AsmFunctionIndex::FootnotesCallback::operator()(bool enabled, const BeforeAfterArgs &args)
{
    if (enabled && args.footnotes) {
        args.footnotes->print(args.output);
    }
    return enabled;
}

