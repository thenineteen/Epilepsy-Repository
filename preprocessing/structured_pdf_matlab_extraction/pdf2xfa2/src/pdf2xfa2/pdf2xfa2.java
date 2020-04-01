/**
 * A PDF form to XFA converter which uses iText 5.
 * Gregory Scott (gregory.scott99@imperial.ac.uk)
 *
 * This code is based on an example written by Bruno Lowagie in answer to:
 * http://stackoverflow.com/questions/28601068/get-names-field-from-interactive-form-pdf
 */
package pdf2xfa2;

import com.itextpdf.text.DocumentException;
import java.io.File;

import java.io.FileOutputStream;
import java.io.IOException;
import javax.xml.parsers.ParserConfigurationException;

import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentCatalog;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDXFAResource;
import org.w3c.dom.Document;

import org.xml.sax.SAXException;

public class pdf2xfa2 {

    public static void main(String[] args)
            throws IOException, DocumentException, TransformerException, ParserConfigurationException, SAXException {
        if (args.length < 1 || args.length > 2) {
            System.out.println(
                    "Usage:\n"
                    + "  pdf2xfa2 <pdf> [<xfa>]");
            System.exit(0);
        } else {
            String in;
            if (args[0].lastIndexOf(".") == -1) {
                in = args[0] + ".pdf";
            } else {
                in = args[0];
            }
            String out;
            if (args.length == 1) {
                out = in.substring(0, in.lastIndexOf("."));
            } else {
                out = args[1];
            }

            if (out.lastIndexOf(".") == -1) {
                out = out + ".xfa";
            }
            new pdf2xfa2().pdf2xfa2(in, out);
        }
    }

    public void pdf2xfa2(String src, String dest)
            throws IOException, DocumentException, TransformerException, ParserConfigurationException, SAXException {

        PDDocument doc = PDDocument.load(new File(src));
        PDDocumentCatalog catalog;
        PDAcroForm acroForm;
        PDXFAResource xfa;
        
        catalog = doc.getDocumentCatalog();
        acroForm = catalog.getAcroForm();
        xfa = acroForm.getXFA();
        
        Document doc2 = xfa.getDocument();
        
        Transformer tf = TransformerFactory.newInstance().newTransformer();
        tf.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        tf.setOutputProperty(OutputKeys.INDENT, "yes");
        FileOutputStream os = new FileOutputStream(dest);
        tf.transform(new DOMSource(doc2), new StreamResult(os));
       
        }
}

        ////PDDocument.loadNonSeq(file,null)

        // getClass().getResourceAsStream("/testform_protected.pdf"), null);
        /*public static byte[] getParsableXFAForm(File file) {
        if (file == null)
            return null;
        PDDocument doc;
        PDDocumentCatalog catalog;
        PDAcroForm acroForm;
        PDXFA xfa;
        try {
            doc = PDDocument.load(file);
    //PDDocument.loadNonSeq(file,null)
            catalog = doc.getDocumentCatalog();
            acroForm = catalog.getAcroForm();
            xfa = acroForm.getXFA();
            byte[] xfaBytes = xfa.getBytes();
            doc.close();
            return xfaBytes;
        } catch (IOException e) {
            // handle IOException
            // happens when the file is corrupt.
            System.out.println("IOException");
            return null;
        }
    }*/
 /*PdfReader reader = new PdfReader(src);
        AcroFields form = reader.getAcroFields();
        XfaForm xfa = form.getXfa();
        
        Node node = xfa.getDatasetsNode();

        Transformer tf = TransformerFactory.newInstance().newTransformer();
        tf.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        tf.setOutputProperty(OutputKeys.INDENT, "yes");
        FileOutputStream os = new FileOutputStream(dest);
        tf.transform(new DOMSource(node), new StreamResult(os));
        reader.close();*/
  