import { Download } from 'lucide-react';
import { Button } from './ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from './ui/dialog';

interface QRDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  clientName: string;
  qrCodeData: string;
  onDownload: () => void;
}

export function QRDialog({
  open,
  onOpenChange,
  clientName,
  qrCodeData,
  onDownload,
}: QRDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 w-[calc(100%-2rem)] sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold text-slate-900 dark:text-white">
            QR код для {clientName}
          </DialogTitle>
          <DialogDescription className="text-slate-500 dark:text-slate-400">
            Отсканируйте QR код в приложении AmneziaWG
          </DialogDescription>
        </DialogHeader>
        <div className="flex justify-center p-4 bg-white rounded-lg">
          {qrCodeData && (
            <img src={qrCodeData} alt="QR Code" className="max-w-full h-auto" />
          )}
        </div>
        <DialogFooter>
          <Button onClick={onDownload} className="w-full bg-blue-600 hover:bg-blue-700">
            <Download className="w-4 h-4 mr-2" />
            Скачать QR (PNG)
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
